# stt_ms — 语音识别推理（faster-whisper + FunASR + 云端 ASR，CPU-only PyTorch）
# Build context: server/   （docker compose 已设置）
FROM python:3.11.17-slim-bookworm
ARG DEBIAN_MIRROR=https://deb.debian.org
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 OPENMEETING_DATA_DIR=/data
# HTTPS 减少软件源 HTTP 链路故障影响；短暂下载失败自动重试，索引不完整时中止构建。
RUN sed -i "s|http://deb.debian.org|${DEBIAN_MIRROR}|g" /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
 && DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::Retries=3 install -y --no-install-recommends ffmpeg libsndfile1 curl \
 && rm -rf /var/lib/apt/lists/*
ENV MODELSCOPE_CACHE=/data/models/.modelscope
COPY --from=ghcr.io/astral-sh/uv:0.13.3 /uv /usr/local/bin/uv

WORKDIR /srv
COPY pyproject.toml uv.lock ./
# stt-cloud is the lightweight runtime; stt-cpu also includes pinned local engines.
ARG STT_EXTRA=stt-cpu
RUN --mount=type=cache,target=/root/.cache/uv \
    case "$STT_EXTRA" in stt-cpu|stt-cloud) ;; *) echo "Unsupported STT_EXTRA" >&2; exit 1 ;; esac \
 && UV_PROJECT_ENVIRONMENT=/opt/venv UV_LINK_MODE=copy \
    uv sync --locked --no-dev --no-install-project --extra "$STT_EXTRA"
ENV VIRTUAL_ENV=/opt/venv PATH=/opt/venv/bin:$PATH

COPY stt_ms/alembic.ini ./stt_ms/alembic.ini
COPY stt_ms/migrations ./stt_ms/migrations
COPY stt_ms ./stt_ms
COPY service_net ./service_net

VOLUME ["/data"]
EXPOSE 39109
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD curl -fsS http://localhost:39109/healthz || exit 1
CMD ["python", "-m", "uvicorn", "stt_ms.main:app", "--host", "0.0.0.0", "--port", "39109"]
