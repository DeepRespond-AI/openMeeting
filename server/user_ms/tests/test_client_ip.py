from user_ms.monitor.connections import client_ip


def test_forwarded_headers_ignored_without_trusted_proxy():
    headers = {"x-forwarded-for": "1.2.3.4", "x-real-ip": "5.6.7.8"}
    assert client_ip(headers, "203.0.113.9", trusted_proxies="") == "203.0.113.9"


def test_forwarded_header_from_trusted_proxy():
    headers = {"x-forwarded-for": "198.51.100.7"}
    assert client_ip(headers, "10.0.0.2", trusted_proxies="10.0.0.0/8") == "198.51.100.7"


def test_spoofed_leftmost_hop_is_ignored():
    # Client sends a fake XFF; the trusted proxy appends the real client address.
    headers = {"x-forwarded-for": "1.1.1.1, 198.51.100.7"}
    assert client_ip(headers, "10.0.0.2", trusted_proxies="10.0.0.0/8") == "198.51.100.7"


def test_chained_trusted_proxies_are_skipped():
    headers = {"x-forwarded-for": "198.51.100.7, 10.0.0.3"}
    assert client_ip(headers, "10.0.0.2", trusted_proxies="10.0.0.0/8") == "198.51.100.7"


def test_real_ip_header_from_trusted_proxy():
    assert client_ip({"x-real-ip": "198.51.100.7"}, "127.0.0.1", trusted_proxies="127.0.0.1") == "198.51.100.7"
