"""MinIO 的 S3 适配器；业务请求继续经过网关认证代理，下载 URL 使用客户端可达地址。"""
from __future__ import annotations

import asyncio
from datetime import timedelta, datetime, timezone
import io
from pathlib import Path
from urllib.parse import urlsplit, quote
import uuid

import urllib3

from service_net.egress import proxy_address

OBJECT_BACKENDS = frozenset({'oss', 'minio'})


def endpoint_parts(endpoint: str) -> tuple[str, bool]:
    parsed = urlsplit(endpoint if '://' in endpoint else f'http://{endpoint}')
    if (parsed.scheme not in {'http', 'https'} or not parsed.hostname or parsed.username or parsed.password
            or parsed.path not in {'', '/'} or parsed.query or parsed.fragment):
        raise ValueError('MinIO Endpoint 必须是 http(s)://主机[:端口]，不能包含路径或凭据')
    return parsed.netloc, parsed.scheme == 'https'


class MinioStore:
    backend = 'minio'

    def __init__(self, cfg, settings):
        from minio import Minio

        self.cfg = cfg
        endpoint, secure = endpoint_parts(cfg.endpoint)
        public, public_secure = endpoint_parts(cfg.public_endpoint or cfg.endpoint)
        proxy = proxy_address(settings)
        options = {'timeout': urllib3.Timeout(connect=10, read=120), 'cert_reqs': 'CERT_REQUIRED',
                   'retries': urllib3.Retry(total=2, backoff_factor=0.2)}
        transport = (urllib3.ProxyManager(proxy, proxy_headers=urllib3.make_headers(
            proxy_basic_auth=f'openmeeting:{settings.internal_service_token}'), **options)
            if proxy else urllib3.PoolManager(**options))
        self.client = Minio(endpoint, access_key=cfg.access_key_id, secret_key=cfg.access_key_secret,
                            secure=secure, region=cfg.region or 'us-east-1', http_client=transport)
        # 指定地域后，生成预签名 URL 不会为了查询地域访问 public_endpoint。
        self.signer = Minio(public, access_key=cfg.access_key_id, secret_key=cfg.access_key_secret,
                            secure=public_secure, region=cfg.region or 'us-east-1', http_client=transport)

    def key(self, *parts: str) -> str:
        return self.cfg.prefix + '/'.join(parts)

    async def upload(self, local_path: Path, key: str, content_type: str | None) -> None:
        await asyncio.to_thread(self.client.fput_object, self.cfg.bucket, key, str(local_path),
                                content_type=content_type or 'application/octet-stream')

    def presign_get(self, key: str, expires: int = 3600) -> str:
        return self.signer.presigned_get_object(self.cfg.bucket, key, expires=timedelta(seconds=expires))

    def presign_put(self, key, proof, content_type, expires):
        # MinIO's URL presigner signs Host only; use its SDK header signer so checksums
        # and metadata cannot be changed. This is a single-request signature, not a key.
        from minio.credentials import Credentials
        from minio.signer import sign_v4_s3
        public, secure = endpoint_parts(self.cfg.public_endpoint or self.cfg.endpoint)
        url = f"{'https' if secure else 'http'}://{public}/{quote(self.cfg.bucket, safe='')}/{quote(key, safe='/')}"
        now = datetime.now(timezone.utc)
        headers = {"Host": public, "Content-Type": content_type, "Content-MD5": proof.md5,
                   "x-amz-content-sha256": proof.sha256, "x-amz-date": now.strftime('%Y%m%dT%H%M%SZ'),
                   "x-amz-meta-sha256": proof.sha256, "x-amz-meta-content-md5": proof.md5}
        signed = sign_v4_s3(method="PUT", url=urlsplit(url), region=self.cfg.region or 'us-east-1', headers=headers,
                            credentials=Credentials(self.cfg.access_key_id, self.cfg.access_key_secret),
                            content_sha256=proof.sha256, date=now)
        signed.pop("Host")  # Browsers set Host from the URL; they cannot set it explicitly.
        return {"url": url, "headers": signed, "expires_in": min(expires, 900)}

    async def stat_object(self, key):
        from minio.error import S3Error
        try:
            stat = await asyncio.to_thread(self.client.stat_object, self.cfg.bucket, key)
        except S3Error as exc:
            if exc.code in {"NoSuchKey", "NoSuchObject", "NotFound"}:
                return None
            raise
        return {"size": stat.size, "etag": stat.etag,
                "metadata": {k.lower().removeprefix("x-amz-meta-"): v for k, v in stat.metadata.items()
                             if k.lower().startswith("x-amz-meta-")}}

    async def copy_object(self, source, target, etag):
        from minio.commonconfig import CopySource
        await asyncio.to_thread(self.client.copy_object, self.cfg.bucket, target,
                                CopySource(self.cfg.bucket, source, match_etag=etag))

    async def delete_object(self, key):
        await asyncio.to_thread(self.client.remove_object, self.cfg.bucket, key)

    async def download_to(self, key: str, path: Path) -> None:
        await asyncio.to_thread(self.client.fget_object, self.cfg.bucket, key, str(path))

    async def delete_prefix(self, prefix: str, keep: str | None = None) -> int:
        from minio.deleteobjects import DeleteObject

        def remove():
            keys = [item.object_name for item in self.client.list_objects(self.cfg.bucket, prefix=prefix, recursive=True)
                    if item.object_name != keep]
            for error in self.client.remove_objects(self.cfg.bucket, (DeleteObject(key) for key in keys)):
                raise RuntimeError(f'MinIO 删除失败：{error.code}')
            return len(keys)

        return await asyncio.to_thread(remove)

    async def test(self) -> None:
        key = self.key('.openmeeting-test', uuid.uuid4().hex)
        payload = b'openmeeting object storage connectivity test'

        def round_trip():
            self.client.put_object(self.cfg.bucket, key, io.BytesIO(payload), len(payload))
            response = None
            try:
                response = self.client.get_object(self.cfg.bucket, key)
                if response.read() != payload:
                    raise RuntimeError('读回的内容与写入的不一致')
            finally:
                if response is not None:
                    response.close()
                    response.release_conn()
                self.client.remove_object(self.cfg.bucket, key)

        await asyncio.to_thread(round_trip)
