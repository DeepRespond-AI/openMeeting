"""Audio decoding, conversion and segmentation helpers (all blocking)."""
from __future__ import annotations

import io
import json
import logging
import shutil
import subprocess
from pathlib import Path

import numpy as np
import soundfile as sf

from stt_ms.stt.base import SAMPLE_RATE, module_available

logger = logging.getLogger(__name__)

MAX_SEGMENT_SEC = 25.0


class AudioDecodeError(Exception):
    pass


def pcm16le_to_float32(data: bytes) -> np.ndarray:
    if len(data) % 2:
        raise AudioDecodeError("PCM16 payload has odd length")
    return np.frombuffer(data, dtype="<i2").astype(np.float32) / 32768.0


def float32_to_wav_bytes(audio: np.ndarray, sample_rate: int = SAMPLE_RATE) -> bytes:
    buf = io.BytesIO()
    sf.write(buf, audio, sample_rate, format="WAV", subtype="PCM_16")
    return buf.getvalue()


def _ffmpeg_decode(path: Path) -> np.ndarray:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise AudioDecodeError("ffmpeg not available")
    proc = subprocess.run(
        [ffmpeg, "-nostdin", "-v", "error", "-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(SAMPLE_RATE), "-"],
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        raise AudioDecodeError(proc.stderr.decode(errors="replace").strip()[-500:] or "ffmpeg failed")
    return pcm16le_to_float32(proc.stdout)


def _resample(audio: np.ndarray, sr: int) -> np.ndarray:
    if sr == SAMPLE_RATE or audio.size == 0:
        return audio
    n_out = int(round(audio.size * SAMPLE_RATE / sr))
    x_old = np.linspace(0.0, 1.0, num=audio.size, endpoint=False)
    x_new = np.linspace(0.0, 1.0, num=n_out, endpoint=False)
    return np.interp(x_new, x_old, audio).astype(np.float32)


def decode_file(path: Path) -> np.ndarray:
    """Decode any audio file to float32 mono 16 kHz (soundfile first, ffmpeg fallback)."""
    try:
        data, sr = sf.read(str(path), dtype="float32", always_2d=True)
        mono = data.mean(axis=1).astype(np.float32)
        if sr == SAMPLE_RATE:
            return mono
        if shutil.which("ffmpeg"):
            return _ffmpeg_decode(path)  # better resampling quality
        return _resample(mono, sr)
    except (sf.LibsndfileError, RuntimeError, TypeError) as exc:
        logger.debug("soundfile could not decode %s (%s); trying ffmpeg", path, exc)
    return _ffmpeg_decode(path)


def probe_duration(path: Path) -> float | None:
    ffprobe = shutil.which("ffprobe")
    if ffprobe:
        proc = subprocess.run(
            [ffprobe, "-v", "error", "-show_entries", "format=duration", "-of", "json", str(path)],
            capture_output=True,
            check=False,
        )
        if proc.returncode == 0:
            try:
                return float(json.loads(proc.stdout)["format"]["duration"])
            except (KeyError, ValueError, TypeError):
                pass
    try:
        info = sf.info(str(path))
        return float(info.duration)
    except Exception:  # noqa: BLE001
        return None


# --------------------------------------------------------------------------- VAD


def _split_long(segments: list[tuple[int, int]], audio: np.ndarray) -> list[tuple[int, int]]:
    """Split segments longer than MAX_SEGMENT_SEC at the quietest 100 ms frame in the last third."""
    max_len = int(MAX_SEGMENT_SEC * SAMPLE_RATE)
    frame = SAMPLE_RATE // 10
    out: list[tuple[int, int]] = []
    for start, end in segments:
        while end - start > max_len:
            lo, hi = start + int(max_len * 0.6), start + max_len
            best, best_energy = hi, float("inf")
            for pos in range(lo, hi - frame, frame):
                energy = float(np.mean(audio[pos : pos + frame] ** 2))
                if energy < best_energy:
                    best, best_energy = pos + frame // 2, energy
            out.append((start, best))
            start = best
        if end - start > SAMPLE_RATE // 10:
            out.append((start, end))
    return out


def _energy_vad(audio: np.ndarray) -> list[tuple[int, int]]:
    frame = int(0.03 * SAMPLE_RATE)
    n = audio.size // frame
    if n == 0:
        return []
    frames = audio[: n * frame].reshape(n, frame)
    db = 10 * np.log10(np.mean(frames**2, axis=1) + 1e-10)
    noise_floor = float(np.percentile(db, 15))
    threshold = max(noise_floor + 10.0, -50.0)
    speech = db > threshold

    min_gap = int(0.5 / 0.03)
    min_speech = int(0.3 / 0.03)
    pad = int(0.2 * SAMPLE_RATE)
    segments: list[tuple[int, int]] = []
    i = 0
    while i < n:
        if not speech[i]:
            i += 1
            continue
        start = i
        silence = 0
        j = i
        while j < n:
            if speech[j]:
                silence = 0
            else:
                silence += 1
                if silence > min_gap:
                    break
            j += 1
        end = j - silence
        if end - start >= min_speech:
            segments.append((max(0, start * frame - pad), min(audio.size, end * frame + pad)))
        i = j
    # Merge overlaps introduced by padding.
    merged: list[tuple[int, int]] = []
    for s, e in segments:
        if merged and s <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(e, merged[-1][1]))
        else:
            merged.append((s, e))
    return merged


_silero_model = None


def _silero_vad(audio: np.ndarray) -> list[tuple[int, int]]:
    global _silero_model
    import torch
    from silero_vad import get_speech_timestamps, load_silero_vad

    if _silero_model is None:
        _silero_model = load_silero_vad()
    stamps = get_speech_timestamps(
        torch.from_numpy(audio), _silero_model, sampling_rate=SAMPLE_RATE, speech_pad_ms=200, min_silence_duration_ms=500
    )
    return [(int(s["start"]), int(s["end"])) for s in stamps]


def vad_split(audio: np.ndarray) -> list[tuple[int, int]]:
    """Speech regions as (start_sample, end_sample), each at most MAX_SEGMENT_SEC long."""
    segments: list[tuple[int, int]] | None = None
    if module_available("silero_vad"):
        try:
            segments = _silero_vad(audio)
        except Exception:  # noqa: BLE001
            logger.exception("silero-vad failed; falling back to energy VAD")
    if segments is None:
        segments = _energy_vad(audio)
    return _split_long(segments, audio)
