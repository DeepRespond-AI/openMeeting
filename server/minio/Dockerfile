# 官方发布已改为源码构建，固定 release tag，避免依赖已下架的 minio/minio 镜像。
FROM python:3.11-slim AS builder
ARG TARGETARCH
ARG MINIO_VERSION=RELEASE.2025-10-15T17-29-55Z
# 默认使用国内 Go 模块下载源，减少当前网络访问官方源时的 EOF 中断；保留 Go 默认校验。
# 可通过 docker compose build --build-arg GOPROXY=https://proxy.golang.org minio 覆盖下载源。
ARG GOPROXY=https://goproxy.cn
COPY minio/install_go.py /tmp/install_go.py
RUN python /tmp/install_go.py ${TARGETARCH}
ENV CGO_ENABLED=0 GOBIN=/out PATH=/usr/local/go/bin:$PATH GOPROXY=${GOPROXY}
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    for attempt in 1 2 3; do go install github.com/minio/minio@${MINIO_VERSION} && exit 0; sleep 3; done; exit 1

FROM python:3.11-slim
COPY --from=builder /out/minio /usr/local/bin/minio
RUN mkdir -p /data && chown 10001:10001 /data
USER 10001:10001
EXPOSE 9000 9001
ENTRYPOINT ["minio"]
CMD ["server", "/data", "--console-address", ":9001"]
