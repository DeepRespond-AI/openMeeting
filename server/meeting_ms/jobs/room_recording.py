"""Durable room audio → attributed transcripts → existing AI summary pipeline."""
import asyncio
import wave
import tempfile
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from sqlalchemy import delete, select

from meeting_ms.config import get_settings
from meeting_ms.storage.audio import meeting_audio_dir, move_local_audio_to_oss
from meeting_ms.storage.recording_chunks import download_pcm
from meeting_ms.db.models import Job, Meeting, RoomRecordingChunk, SummaryProcess, Transcript
from meeting_ms.db.session import session_factory
from meeting_ms.infrastructure.stt_client import SttClient
from meeting_ms.jobs import store
from meeting_ms.llm.providers import get_active_provider
from meeting_ms.summary import service
from meeting_ms.utils import iso_ms, new_uuid, utcnow


def mix_wav(chunks, path):
    # Stream in one-second windows: memory is bounded even for a twelve-hour room.
    ends = [round(c.start_time * 16000) + c.size // 2 for c in chunks]
    ordered = sorted(zip(chunks, ends), key=lambda pair: pair[0].start_time)
    cursor, active = 0, []
    length = max(ends)
    with wave.open(str(path), "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(16000)
        for offset in range(0, length, 16000):
            size = min(16000, length - offset)
            window = np.zeros(size, dtype=np.int32)
            while cursor < len(ordered) and round(ordered[cursor][0].start_time * 16000) < offset + size:
                active.append(ordered[cursor])
                cursor += 1
            active = [(c, end) for c, end in active if end > offset]
            for chunk, end in active:
                start = round(chunk.start_time * 16000)
                a, b = max(offset, start), min(offset + size, end)
                if a < b:
                    with chunk.path.open("rb") as source:
                        source.seek((a-start) * 2)
                        data = source.read((b-a) * 2)
                    samples = np.frombuffer(data, dtype="<i2")
                    window[a-offset:b-offset] += samples
            out.writeframes(np.clip(window, -32768, 32767).astype("<i2").tobytes())
    return length / 16000


async def run(job: Job, check):
    await store.update_job(job.id, status="running", progress=1, message="正在合成会议录音")
    try:
        tmp_root = get_settings().data_dir / "tmp"
        tmp_root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="room-pcm-", dir=tmp_root) as directory:
            await _process(job, check, Path(directory))
    except asyncio.CancelledError:
        # A shutdown is recovered by JobRunner; acknowledged chunks stay durable.
        raise
    except Exception as exc:
        await store.update_job(job.id, status="failed", error=str(exc), message="会后处理失败，可重试")


async def _process(job, check, directory):
    async with session_factory()() as session:
        meeting = await session.get(Meeting, job.meeting_id)
        chunks = list((await session.execute(select(RoomRecordingChunk).where(
            RoomRecordingChunk.room_id == job.params["room_id"]).order_by(
            RoomRecordingChunk.start_time, RoomRecordingChunk.created_at, RoomRecordingChunk.id))).scalars())
    if meeting is None:
        raise RuntimeError("会议记录不存在")
    if not chunks:
        raise RuntimeError("未收到会议音频，请确认主持人已连接音视频并允许录制")
    path = meeting_audio_dir(meeting) / 'room.wav'
    path.parent.mkdir(parents=True, exist_ok=True)
    sources = []
    for i, chunk in enumerate(chunks):
        check(job.id)
        local = directory / f"{i}.pcm"
        await download_pcm(chunk, local)
        sources.append(SimpleNamespace(path=local, size=local.stat().st_size, start_time=chunk.start_time))
    # A cancelled coroutine must not remove temporary source files under a running thread.
    mixing = asyncio.create_task(asyncio.to_thread(mix_wav, sources, path))
    try:
        duration = await asyncio.shield(mixing)
    except asyncio.CancelledError:
        await mixing
        raise
    check(job.id)
    async with session_factory()() as session:
        row = await session.get(Meeting, meeting.id)
        row.audio_path, row.audio_storage, row.audio_content_type = str(path), "local", "audio/wav"
        row.audio_size, row.duration, row.updated_at = path.stat().st_size, duration, utcnow()
        await session.commit()
    # 对象存储失败仍保留本地录音和已确认的 PCM 分片，以便重试。
    await move_local_audio_to_oss(meeting.id)
    await store.update_job(job.id, progress=10, message="正在按参会者转写")
    stt = SttClient()
    if not await stt.ready():
        raise RuntimeError("语音识别模型未就绪，录音已保存，配置模型后可重试")
    speakers, transcripts = {}, []
    for i, chunk in enumerate(chunks):
        check(job.id)
        # Each track has an authenticated identity, including equal display names.
        if chunk.participant_id not in speakers:
            speakers[chunk.participant_id] = f"{len(speakers)+1}·{chunk.speaker_name[:28]}"
        pcm = await asyncio.to_thread(sources[i].path.read_bytes)
        result = await stt.transcribe_pcm(pcm, None)
        if result.text.strip():
            duration = len(pcm) / 32000
            transcripts.append(Transcript(id=new_uuid(), meeting_id=meeting.id, seq=i,
                transcript=result.text.strip(), timestamp=iso_ms(utcnow()),
                audio_start_time=chunk.start_time, audio_end_time=chunk.start_time+duration,
                duration=duration, speaker=speakers[chunk.participant_id], confidence=result.confidence))
        await store.update_job(job.id, progress=10+int(65*(i+1)/len(chunks)), message="正在按参会者转写")
    check(job.id)
    async with session_factory()() as session:
        await session.execute(delete(Transcript).where(Transcript.meeting_id == meeting.id))
        session.add_all(transcripts)
        await session.commit()
    if not transcripts:
        raise RuntimeError("录音中未识别到语音，未生成 AI 纪要")
    provider = await get_active_provider()
    if provider is None:
        raise RuntimeError("服务器尚未配置可用的大模型，录音和转写已保存，配置后可重试")
    await store.update_job(job.id, progress=80, message="正在生成 AI 纪要")
    await service.start_summary(meeting, provider, service.format_transcript_text(transcripts), None)
    await service._running[meeting.id].task
    check(job.id)
    async with session_factory()() as session:
        summary = await session.get(SummaryProcess, meeting.id)
        if summary is None or summary.status.lower() != "completed":
            raise RuntimeError(summary.error if summary and summary.error else "AI 纪要生成失败")
    await store.update_job(job.id, status="completed", progress=100, segments=len(transcripts), message="会议录音、转写和 AI 纪要已完成")
