"""Fail-closed external HTTP transport through the gateway's authenticated forward proxy."""
from __future__ import annotations

import os
from typing import Any
from urllib.parse import quote, urlsplit, urlunsplit

import httpx


def proxy_address(settings: Any) -> str | None:
    address = settings.egress_proxy_url.strip().rstrip('/')
    if not address:
        if settings.is_dev:
            return None  # Explicit OPENMEETING_EGRESS_PROXY_URL="" is allowed only in isolated dev/tests.
        raise RuntimeError('OPENMEETING_EGRESS_PROXY_URL is required for external connections')
    parsed = urlsplit(address)
    if (parsed.scheme != 'http' or not parsed.hostname or parsed.username or parsed.password
            or parsed.path or parsed.query or parsed.fragment):
        raise RuntimeError('Invalid gateway egress proxy URL')
    if not settings.internal_service_token:
        raise RuntimeError('Internal service token is required for the egress proxy')
    return address


def proxy_options(settings: Any) -> dict:
    address = proxy_address(settings)
    return {'trust_env': False, 'proxy': httpx.Proxy(address, auth=('openmeeting', settings.internal_service_token))
            if address else None}


def async_client(settings: Any, **kwargs) -> httpx.AsyncClient:
    return httpx.AsyncClient(**kwargs, **proxy_options(settings))


def sync_client(settings: Any, **kwargs) -> httpx.Client:
    return httpx.Client(**kwargs, **proxy_options(settings))


def authenticated_proxy_url(settings: Any) -> str | None:
    address = proxy_address(settings)
    if not address:
        return None
    parsed = urlsplit(address)
    return urlunsplit((parsed.scheme, 'openmeeting:' + quote(settings.internal_service_token, safe='') + '@' + parsed.netloc, '', '', ''))


def configure_requests(session: Any, settings: Any) -> Any:
    address = authenticated_proxy_url(settings)
    session.trust_env = False
    session.proxies = {'http': address, 'https': address} if address else {}
    return session


def configure_sdk_environment(settings: Any) -> None:
    """Libraries that own their HTTP/WS clients use the same proxy, with no NO_PROXY escape."""
    address = authenticated_proxy_url(settings)
    if address:
        for name in ('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'http_proxy', 'https_proxy', 'all_proxy'):
            os.environ[name] = address
        os.environ['NO_PROXY'] = os.environ['no_proxy'] = ''
        # Native download accelerators don't use Python's configured HTTP client.
        os.environ['HF_HUB_DISABLE_XET'] = '1'
        os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '0'
