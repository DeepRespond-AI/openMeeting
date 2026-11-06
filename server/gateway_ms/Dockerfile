# gateway_ms — 统一入口（认证 + 路径转发 + admin SPA 托管）
# Build context: server/   （docker compose 已设置）

# ---------- admin web (Vue SPA) ----------
FROM node:20-slim AS admin-web
WORKDIR /build/admin-web
RUN corepack enable && corepack prepare pnpm@10.6.5 --activate
COPY admin-web/package.json admin-web/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY admin-web/ ./
RUN pnpm build  # outputs to /build/gateway_ms/static/admin

# ---------- python runtime ----------
FROM python:3.11.17-slim-bookworm
ARG DEBIAN_MIRROR=https://deb.debian.org
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
# HTTPS 减少软件源 HTTP 链路故障影响；短暂下载失败自动重试，索引不完整时中止构建。
RUN sed -i "s|http://deb.debian.org|${DEBIAN_MIRROR}|g" /etc/apt/sources.list.d/debian.sources \
 && apt-get -o Acquire::Retries=3 -o APT::Update::Error-Mode=any update \
 && apt-get -o Acquire::Retries=3 install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:0.13.3 /uv /usr/local/bin/uv

WORKDIR /srv
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    UV_PROJECT_ENVIRONMENT=/opt/venv UV_LINK_MODE=copy \
    uv sync --locked --no-dev --no-install-project
ENV VIRTUAL_ENV=/opt/venv PATH=/opt/venv/bin:$PATH

COPY gateway_ms ./gateway_ms
COPY --from=admin-web /build/gateway_ms/static/admin ./gateway_ms/static/admin

EXPOSE 39110 39111
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s CMD curl -fsS http://localhost:39110/healthz || exit 1
CMD ["python", "-m", "uvicorn", "gateway_ms.main:app", "--host", "0.0.0.0", "--port", "39110", "--proxy-headers", "--forwarded-allow-ips", "*"]
