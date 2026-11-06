"""Run in the existing STT container; sample real model bytes without storing weights.

PowerShell, repository root:
Get-Content -Raw tests/e2e/model-download-egress.py | docker exec -i <stt-container> python -
Output is JSON Lines. Uses actual service_net proxy auth and TLS verification.
"""
import base64
import json
import logging
import socket
from urllib.parse import urlsplit

from service_net.egress import configure_sdk_environment, proxy_address
from stt_ms.config import get_settings

logging.disable(logging.CRITICAL)
settings = get_settings()
configure_sdk_environment(settings)
proxy = urlsplit(proxy_address(settings))
checks = []


def record(operation, expected, actual, passed):
    result = dict(operation=operation, expected=expected, actual=actual, passed=passed, screenshot=None)
    checks.append(result)
    print(json.dumps(result, ensure_ascii=False), flush=True)


# Deterministic failure paths run first, before browser acceptance.
for label, target, authenticated, expected in [
    ('unlisted destination denied', 'unlisted-model.example.invalid:443', True, 403),
    ('unlisted port denied', 'modelscope.cn:22', True, 403),
    ('metadata address denied', '169.254.169.254:443', True, 403),
    ('proxy authentication required', 'modelscope.cn:443', False, 407),
]:
    try:
        with socket.create_connection((proxy.hostname, proxy.port), timeout=10) as connection:
            credentials = base64.b64encode(('openmeeting:' + settings.internal_service_token).encode()).decode()
            auth = 'Proxy-Authorization: Basic ' + credentials + '\r\n' if authenticated else ''
            connection.sendall(('CONNECT ' + target + ' HTTP/1.1\r\nHost: ' + target + '\r\n' + auth + '\r\n').encode())
            response = connection.recv(4096)
            status = int(response.split()[1])
            record(label, expected, status, status == expected)
    except Exception as error:
        record(label, expected, dict(error_type=type(error).__name__), False)

import requests  # noqa: E402

sources = [
    ('ModelScope file listing', 'https://modelscope.cn/api/v1/models/iic/SenseVoiceSmall/repo/files?Revision=master&Recursive=True'),
    ('ModelScope small configuration', 'https://modelscope.cn/api/v1/models/iic/SenseVoiceSmall/repo?Revision=master&FilePath=configuration.json'),
    ('ModelScope weight CDN sample', 'https://modelscope.cn/api/v1/models/iic/SenseVoiceSmall/repo?Revision=master&FilePath=model.pt'),
    ('Hugging Face small configuration', 'https://huggingface.co/Systran/faster-whisper-tiny/resolve/main/config.json'),
    ('Hugging Face weight CDN sample', 'https://huggingface.co/Systran/faster-whisper-tiny/resolve/main/model.bin'),
]
for label, url in sources:
    try:
        # Always stream and close after <=1 KiB, even if an origin ignores Range.
        with requests.Session() as session:
            with session.get(url, headers={'Range': 'bytes=0-1023'}, stream=True, timeout=(8, 20)) as response:
                sample = next(response.iter_content(chunk_size=1024), b'')
                actual = dict(status=response.status_code, bytes_sampled=len(sample),
                              redirect_hosts=[urlsplit(r.url).hostname for r in [*response.history, response]],
                              tls_verification=True, gateway_host=proxy.hostname)
                record(label, 'HTTP 200/206 and 1..1024 sampled bytes via gateway', actual,
                       response.status_code in (200, 206) and 0 < len(sample) <= 1024)
    except Exception as error:
        # Exception strings may contain signed URLs / proxy credentials: output type only.
        record(label, 'HTTP 200/206 and sampled model bytes', dict(error_type=type(error).__name__), False)

raise SystemExit(0 if all(row['passed'] for row in checks) else 1)
