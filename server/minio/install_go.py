"""从 Go 官方下载编译工具并核验固定版本 SHA-256，不依赖额外的 Go 基础镜像。"""
import hashlib
from pathlib import Path
import sys
import tarfile
import time
import urllib.request

SHA256 = {
    'amd64': '6842c516ca66c89d648a7f1dbe28e28c47b61b59f8f06633eb2ceb1188e9251d',
    'arm64': '38ac33b4cfa41e8a32132de7a87c6db49277ab5c0de1412512484db1ed77637e',
}
arch = sys.argv[1]
archive = Path('/tmp/go.tar.gz')
for attempt in range(3):
    try:
        with urllib.request.urlopen(f'https://go.dev/dl/go1.24.8.linux-{arch}.tar.gz', timeout=30) as source:
            with archive.open('wb') as destination:
                while chunk := source.read(1024 * 1024):
                    destination.write(chunk)
        break
    except Exception:
        if attempt == 2:
            raise
        time.sleep(2)
with archive.open('rb') as downloaded:
    digest = hashlib.file_digest(downloaded, 'sha256').hexdigest()
if digest != SHA256[arch]:
    raise RuntimeError('Go 下载文件校验失败')
with tarfile.open(archive) as source:
    source.extractall('/usr/local', filter='data')
archive.unlink()
