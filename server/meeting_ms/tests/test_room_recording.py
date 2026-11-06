import asyncio
import base64
import io
import wave

import httpx
import numpy as np
import respx

from meeting_ms.tests.conftest import user_headers
from meeting_ms.tests.test_rooms import ALICE, BOB, join, make_room, make_scheduled
from meeting_ms.tests.test_summary import FakeLlm, LLM_BASE
from meeting_ms.tests.test_scheduled import future_iso


async def wait_job(client, mid):
    for _ in range(200):
        value = (await client.get(f"/api/v1/meetings/{mid}/recording", headers=ALICE())).json()
        if value["status"] in ("completed", "failed", "cancelled"):
            return value
        await asyncio.sleep(0.05)
    raise AssertionError("room recording job timed out")


def chunk(participant, key="chunk-1", start=0, epoch=1):
    data = (np.sin(np.arange(16000)*0.13)*10000).astype("<i2").tobytes()
    return {"chunkId": key, "participantId": participant, "startTime": start, "pcm": base64.b64encode(data).decode(), "epoch": epoch}


async def start_recording(client, room):
    result = await client.post(f"/api/v1/rooms/{room['id']}/recording/control", headers=ALICE(),
        json={"action":"start", "epoch":room['recording']['epoch']})
    assert result.status_code == 200, result.text
    return result.json()


async def test_attributed_audio_to_real_summary_pipeline(client, fake_stt):
    fake = FakeLlm()
    with respx.mock(assert_all_called=False) as mock:
        mock.post(f"{LLM_BASE}/chat/completions").mock(side_effect=fake)
        result = await client.post("/admin/api/llm/providers", json={"name": "fixture", "base_url": LLM_BASE, "model": "test", "api_key": "test"})
        assert result.status_code == 200, result.text
        room = await make_room(client)
        await start_recording(client, room)
        member = (await join(client, room["code"], BOB())).json()["self"]
        for i, participant in enumerate((room["participants"][0], member)):
            response = await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(), json=chunk(participant["id"], f"chunk-{i}", i))
            assert response.status_code == 201, response.text
        end = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()
        job = await wait_job(client, end["meetingId"])
        assert job["status"] == "completed", job
        details = (await client.get(f"/api/v1/meetings/{end['meetingId']}", headers=ALICE())).json()
        assert [t["speaker"] for t in details["transcripts"]] == ["1·alice", "2·bob"]
        paged = (await client.get(f"/api/v1/meetings/{end['meetingId']}/transcripts", headers=ALICE())).json()
        assert paged["transcripts"][1]["speaker"] == "2·bob"
        summary = (await client.get(f"/api/v1/meetings/{end['meetingId']}/summary", headers=ALICE())).json()
        assert summary["status"] == "completed"
        assert any("1·alice" in str(c) and "2·bob" in str(c) for c in fake.calls)


async def test_chunk_security_validation_and_idempotency(client):
    room = await make_room(client)
    await start_recording(client, room)
    member = (await join(client, room["code"], BOB())).json()["self"]
    url = f"/api/v1/rooms/{room['id']}/recording/chunks"
    payload = chunk(member["id"])
    assert (await client.post(url, headers=BOB(), json=payload)).status_code == 403
    assert (await client.post(url, json=payload)).status_code == 401
    for value in ("", "not base64", base64.b64encode(b"x").decode(), base64.b64encode(bytes(320002)).decode()):
        assert (await client.post(url, headers=ALICE(), json={**payload, "pcm": value})).status_code == 422
    assert (await client.post(url, headers=ALICE(), json={**payload, "participantId": "foreign"})).status_code == 422
    for _ in range(2):
        assert (await client.post(url, headers=ALICE(), json=payload)).status_code == 201
    assert (await client.post(url, headers=ALICE(), json={**payload, "startTime": 1})).status_code == 409
    assert (await client.post(url, headers=ALICE(), json={**payload, "chunkId": "oversize-time", "startTime": 43200})).status_code == 422
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()["meetingId"]
    assert (await client.post(url, headers=ALICE(), json=payload)).status_code == 409
    assert (await client.get(f"/api/v1/meetings/{mid}/recording", headers=BOB())).status_code == 200
    await wait_job(client, mid)


async def test_empty_audio_fails_explicitly(client):
    room = await make_room(client)
    await start_recording(client, room)
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()["meetingId"]
    job = await wait_job(client, mid)
    assert job["status"] == "failed" and "未收到" in job["error"]


async def test_stt_failure_retains_audio_and_retry_retains_transcripts(client, fake_stt):
    room = await make_room(client)
    await start_recording(client, room)
    await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(), json=chunk(room["hostId"]))
    fake_stt.ready = False
    mid = (await client.post(f"/api/v1/rooms/{room['id']}/end", headers=ALICE())).json()["meetingId"]
    job = await wait_job(client, mid)
    assert job["status"] == "failed" and "模型未就绪" in job["error"]
    metadata = (await client.get(f"/api/v1/meetings/{mid}/metadata", headers=ALICE())).json()
    assert metadata["has_audio"] is True
    fake_stt.ready = True
    assert (await client.post(f"/api/v1/meetings/{mid}/recording/retry", headers=ALICE())).status_code == 202
    job = await wait_job(client, mid)
    assert job["status"] == "failed" and "大模型" in job["error"]
    rows = (await client.get(f"/api/v1/meetings/{mid}", headers=ALICE())).json()["transcripts"]
    assert len(rows) == 1 and rows[0]["speaker"] == "1·alice"


async def test_scheduled_update_cancel_ownership_and_started_guard(client):
    sched = await make_scheduled(client)
    url = f"/api/v1/scheduled-meetings/{sched['id']}"
    data = {"title": "updated", "startAt": future_iso(60), "durationMin": 90, "remind": True}
    assert (await client.patch(url, headers=BOB(), json=data)).status_code == 404
    assert (await client.patch(url, headers=ALICE(), json={**data, "durationMin": 3})).status_code == 422
    updated = (await client.patch(url, headers=ALICE(), json=data)).json()
    assert updated["code"] == sched["code"] and updated["title"] == "updated" and updated["remind"]
    assert (await client.delete(url, headers=ALICE())).status_code == 204
    assert (await client.delete(url, headers=ALICE())).status_code == 204
    assert (await client.get(url, headers=ALICE())).json()["cancelled"]
    assert (await join(client, sched["code"], ALICE())).status_code == 404
    assert (await client.patch(url, headers=ALICE(), json=data)).status_code == 409
    sched = await make_scheduled(client)
    await make_room(client, scheduledMeetingId=sched["id"])
    url = f"/api/v1/scheduled-meetings/{sched['id']}"
    assert (await client.patch(url, headers=ALICE(), json=data)).status_code == 409
    assert (await client.delete(url, headers=ALICE())).status_code == 409


async def test_departed_member_final_buffer_and_waiting_member_denied(client):
    room = await make_room(client)
    await start_recording(client, room)
    member = (await join(client, room["code"], BOB())).json()["self"]
    assert (await client.post(f"/api/v1/rooms/{room['id']}/leave", headers=BOB())).status_code == 204
    # Leave removes the roster row, but authenticated speaker provenance survives.
    response = await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(), json=chunk(member["id"]))
    assert response.status_code == 201
    sched = await make_scheduled(client, waitRoom=True)
    room = await make_room(client, scheduledMeetingId=sched["id"])
    await start_recording(client, room)
    waiting = (await join(client, room["code"], BOB())).json()["self"]
    response = await client.post(f"/api/v1/rooms/{room['id']}/recording/chunks", headers=ALICE(), json=chunk(waiting["id"]))
    assert response.status_code == 422


async def test_mix_preserves_gaps_overlap_and_clips(tmp_path):
    from types import SimpleNamespace
    from meeting_ms.jobs.room_recording import mix_wav
    path = tmp_path / "mixed.wav"
    chunks = []
    for i, (start, count, value) in enumerate([(0, 32000, 20000), (1, 32000, 20000), (4, 16000, 1000)]):
        source = tmp_path / f"{i}.pcm"
        source.write_bytes(np.full(count, value, dtype="<i2").tobytes())
        chunks.append(SimpleNamespace(start_time=start, path=source, size=source.stat().st_size))
    assert mix_wav(chunks, path) == 5
    with wave.open(str(path)) as audio:
        assert audio.getframerate() == 16000 and audio.getnchannels() == 1
        samples = np.frombuffer(audio.readframes(audio.getnframes()), dtype="<i2")
    assert np.all(samples[:16000] == 20000)
    assert np.all(samples[16000:32000] == 32767)
    assert np.all(samples[48000:64000] == 0)
    assert np.all(samples[64000:] == 1000)
