"""Aliyun RPC signature v1 — checked against the examples in Aliyun's documentation (no DB needed)."""
from __future__ import annotations

from datetime import UTC, datetime

from user_ms.auth import aliyun_sms
from user_ms.auth.sms import normalize_phone


def test_documented_rpc_example() -> None:
    # "签名机制" doc example (ECS DescribeRegions, GET).
    params = {
        "Timestamp": "2016-02-23T12:46:24Z",
        "Format": "XML",
        "AccessKeyId": "testid",
        "Action": "DescribeRegions",
        "SignatureMethod": "HMAC-SHA1",
        "SignatureNonce": "3ee8c1b8-83d3-44af-a94f-4e0ad82fd6cf",
        "Version": "2014-05-26",
        "SignatureVersion": "1.0",
    }
    assert aliyun_sms.string_to_sign(params, "GET") == (
        "GET&%2F&AccessKeyId%3Dtestid%26Action%3DDescribeRegions%26Format%3DXML%26SignatureMethod%3DHMAC-SHA1"
        "%26SignatureNonce%3D3ee8c1b8-83d3-44af-a94f-4e0ad82fd6cf%26SignatureVersion%3D1.0"
        "%26Timestamp%3D2016-02-23T12%253A46%253A24Z%26Version%3D2014-05-26"
    )
    assert aliyun_sms.sign(params, "testsecret", "GET") == "OLeaidS1JvxuMvnyHOwuJ+uX5qY="


def test_documented_sendsms_example() -> None:
    # dysmsapi SendSms signature demo (UTF-8 SignName, JSON TemplateParam).
    params = {
        "AccessKeyId": "testId",
        "Action": "SendSms",
        "Format": "XML",
        "OutId": "123",
        "PhoneNumbers": "15300000001",
        "RegionId": "cn-hangzhou",
        "SignName": "阿里云短信测试专用",
        "SignatureMethod": "HMAC-SHA1",
        "SignatureNonce": "45e25e9b-0a6f-4070-8c85-2956eda1b466",
        "SignatureVersion": "1.0",
        "TemplateCode": "SMS_71390007",
        "TemplateParam": '{"customer":"test"}',
        "Timestamp": "2017-07-12T02:42:19Z",
        "Version": "2017-05-25",
    }
    assert aliyun_sms.sign(params, "testSecret", "GET") == "zJDF+Lrzhj/ThnlvIToysFRq6t4="


def test_percent_encode() -> None:
    assert aliyun_sms.percent_encode("a b*c~d/e+f") == "a%20b%2Ac~d%2Fe%2Bf"
    assert aliyun_sms.percent_encode("中") == "%E4%B8%AD"


def test_build_params_deterministic() -> None:
    kwargs = dict(
        access_key_id="LTAIkey", access_key_secret="secret", phone="13800138000", sign_name="深应会议",
        template_code="SMS_1", template_param={"code": "123456"}, nonce="nonce-1",
        timestamp=datetime(2026, 10, 7, 3, 59, 35, tzinfo=UTC),
    )
    a = aliyun_sms.build_send_sms_params(**kwargs)
    b = aliyun_sms.build_send_sms_params(**kwargs)
    assert a == b
    assert a["Timestamp"] == "2026-10-07T03:59:35Z" and a["TemplateParam"] == '{"code":"123456"}'
    unsigned = {k: v for k, v in a.items() if k != "Signature"}
    assert a["Signature"] == aliyun_sms.sign(unsigned, "secret", "POST")
    assert aliyun_sms.build_send_sms_params(**{**kwargs, "nonce": "nonce-2"})["Signature"] != a["Signature"]


def test_error_mapping() -> None:
    assert aliyun_sms.describe_error("isv.BUSINESS_LIMIT_CONTROL", "x").startswith("短信发送过于频繁")
    assert aliyun_sms.describe_error("isv.UNKNOWN", "boom") == "短信发送失败：boom（isv.UNKNOWN）"


def test_normalize_phone() -> None:
    assert normalize_phone("13800138000") == "13800138000"
    assert normalize_phone("+86 138-0013-8000") == "13800138000"
    assert normalize_phone("8613800138000") == "13800138000"
    assert normalize_phone("0086 13800138000") == "13800138000"
    assert normalize_phone("(138) 0013 8000") == "13800138000"
    for bad in ("", None, "12800138000", "1380013800", "138001380000", "abc", "+1 4155550100"):
        assert normalize_phone(bad) is None
