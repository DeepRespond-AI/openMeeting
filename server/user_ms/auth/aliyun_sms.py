"""Minimal Aliyun Short Message Service client: `SendSms` (dysmsapi 2017-05-25), RPC signature v1 (HMAC-SHA1)."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
import logging
import uuid
from dataclasses import dataclass
from datetime import datetime
from urllib.parse import quote

import httpx

from user_ms.utils import utcnow
from user_ms.config import get_settings
from service_net.egress import async_client

logger = logging.getLogger(__name__)

DEFAULT_ENDPOINT = "dysmsapi.aliyuncs.com"
API_VERSION = "2017-05-25"

# Common SendSms error codes -> Chinese messages (others fall back to Aliyun's own `Message`).
ERROR_MESSAGES: dict[str, str] = {
    "isv.BUSINESS_LIMIT_CONTROL": "短信发送过于频繁（运营商流控），请稍后再试",
    "isv.DAY_LIMIT_CONTROL": "该手机号今日接收短信已达上限",
    "isv.MOBILE_NUMBER_ILLEGAL": "手机号码格式错误",
    "isv.MOBILE_COUNT_OVER_LIMIT": "手机号码数量超过限制",
    "isv.SMS_SIGNATURE_ILLEGAL": "短信签名不可用（未审核通过或不存在）",
    "isv.SMS_SIGN_ILLEGAL": "短信签名不可用（未审核通过或不存在）",
    "isv.SMS_TEMPLATE_ILLEGAL": "短信模板不可用（未审核通过或不存在）",
    "isv.TEMPLATE_MISSING_PARAMETERS": "短信模板变量缺失，请检查模板变量名",
    "isv.TEMPLATE_PARAMS_ILLEGAL": "短信模板变量不合法",
    "isv.INVALID_PARAMETERS": "短信请求参数错误",
    "isv.INVALID_JSON_PARAM": "短信模板参数格式错误",
    "isv.AMOUNT_NOT_ENOUGH": "短信账户余额不足",
    "isv.OUT_OF_SERVICE": "短信服务已停机（账户欠费）",
    "isv.ACCOUNT_NOT_EXISTS": "阿里云账户不存在",
    "isv.ACCOUNT_ABNORMAL": "阿里云账户异常",
    "isv.PRODUCT_UN_SUBSCRIPT": "未开通短信服务",
    "isv.PRODUCT_UNSUBSCRIBE": "未开通短信服务",
    "isv.BLACK_KEY_CONTROL_LIMIT": "短信内容包含禁止发送的关键字",
    "isv.DENY_IP_RANGE": "该 IP 不允许调用短信服务",
    "isv.EXTEND_CODE_ERROR": "扩展码使用错误",
    "isp.SYSTEM_ERROR": "阿里云短信服务系统错误，请稍后再试",
    "isp.RAM_PERMISSION_DENY": "AccessKey 无短信权限，请为 RAM 用户授予 AliyunDysmsFullAccess",
    "Forbidden.NoPermission": "AccessKey 无短信权限，请为 RAM 用户授予 AliyunDysmsFullAccess",
    "InvalidAccessKeyId.NotFound": "AccessKey ID 不存在",
    "InvalidAccessKeyId.Inactive": "AccessKey ID 已被禁用",
    "SignatureDoesNotMatch": "AccessKey Secret 错误（签名不匹配）",
    "SignatureNonceUsed": "请求重复，请重试",
    "InvalidTimeStamp.Expired": "服务器时间不准确，请校准系统时间",
}


@dataclass(frozen=True)
class SmsSendResult:
    ok: bool
    code: str | None
    message: str | None  # Chinese, user facing (None when ok)
    request_id: str | None


def percent_encode(value: str) -> str:
    """Aliyun RPC percent-encoding: RFC 3986 unreserved chars kept, UTF-8, space -> %20, `*` -> %2A, `~` kept."""
    return quote(str(value), safe="~")


def string_to_sign(params: dict[str, str], method: str = "POST") -> str:
    canonical = "&".join(f"{percent_encode(k)}={percent_encode(v)}" for k, v in sorted(params.items()))
    return f"{method.upper()}&{percent_encode('/')}&{percent_encode(canonical)}"


def sign(params: dict[str, str], access_key_secret: str, method: str = "POST") -> str:
    digest = hmac.new(
        (access_key_secret + "&").encode(), string_to_sign(params, method).encode(), hashlib.sha1
    ).digest()
    return base64.b64encode(digest).decode()


def format_timestamp(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def build_send_sms_params(
    *,
    access_key_id: str,
    access_key_secret: str,
    phone: str,
    sign_name: str,
    template_code: str,
    template_param: dict[str, str],
    nonce: str | None = None,
    timestamp: datetime | None = None,
    method: str = "POST",
) -> dict[str, str]:
    params = {
        "AccessKeyId": access_key_id,
        "Action": "SendSms",
        "Format": "JSON",
        "PhoneNumbers": phone,
        "RegionId": "cn-hangzhou",
        "SignName": sign_name,
        "SignatureMethod": "HMAC-SHA1",
        "SignatureNonce": nonce or uuid.uuid4().hex,
        "SignatureVersion": "1.0",
        "TemplateCode": template_code,
        "TemplateParam": json.dumps(template_param, ensure_ascii=False, separators=(",", ":")),
        "Timestamp": format_timestamp(timestamp or utcnow()),
        "Version": API_VERSION,
    }
    params["Signature"] = sign(params, access_key_secret, method)
    return params


def describe_error(code: str | None, message: str | None) -> str:
    if code and code in ERROR_MESSAGES:
        return ERROR_MESSAGES[code]
    if message:
        return f"短信发送失败：{message}" + (f"（{code}）" if code else "")
    return "短信发送失败" + (f"（{code}）" if code else "")


async def send_sms(
    *,
    endpoint: str,
    access_key_id: str,
    access_key_secret: str,
    phone: str,
    sign_name: str,
    template_code: str,
    template_param: dict[str, str],
    timeout: float = 10.0,
) -> SmsSendResult:
    params = build_send_sms_params(
        access_key_id=access_key_id,
        access_key_secret=access_key_secret,
        phone=phone,
        sign_name=sign_name,
        template_code=template_code,
        template_param=template_param,
    )
    host = (endpoint or DEFAULT_ENDPOINT).strip().removeprefix("https://").removeprefix("http://").rstrip("/")
    try:
        async with async_client(get_settings(), timeout=timeout) as client:
            resp = await client.post(f"https://{host}/", data=params)
    except httpx.HTTPError as exc:
        logger.warning("Aliyun SendSms request failed: %s", exc)
        return SmsSendResult(False, None, f"无法连接阿里云短信服务：{exc.__class__.__name__}", None)
    try:
        body = resp.json()
    except ValueError:
        return SmsSendResult(False, None, f"阿里云短信服务返回异常（HTTP {resp.status_code}）", None)
    code = body.get("Code")
    request_id = body.get("RequestId")
    if code == "OK":
        return SmsSendResult(True, code, None, request_id)
    logger.warning("Aliyun SendSms error: code=%s message=%s request_id=%s", code, body.get("Message"), request_id)
    return SmsSendResult(False, code, describe_error(code, body.get("Message")), request_id)
