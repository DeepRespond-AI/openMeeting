"""HTTP acceptance against the isolated direct-upload fixture and real MinIO."""
import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
import sys
import time
import wave
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "server"))
import httpx
import jwt

parser = argparse.ArgumentParser()
parser.add_argument("--base", default="http://127.0.0.1:39362")
parser.add_argument("--out", default=str(ROOT / ".artifacts/direct-upload-20261105"))
args = parser.parse_args()
out = Path(args.out); out.mkdir(parents=True, exist_ok=True)
if (out / "api-results.json").exists():
    (out / "api-results.json").rename(out / f"api-results-attempt-{time.time_ns()}.json")
steps = []

def check(operation, expected, actual, passed):
    row = {"operation": operation, "expected": expected, "actual": actual, "passed": bool(passed), "screenshot": None}
    steps.append(row)
    print(json.dumps(row, ensure_ascii=False), flush=True)
    (out / "api-results.json").write_text(json.dumps({"steps": steps, "passed": sum(s['passed'] for s in steps),
        "failed": sum(not s['passed'] for s in steps)}, ensure_ascii=False, indent=2), encoding="utf-8")
    assert passed, operation

api = httpx.Client(base_url=args.base, timeout=20, trust_env=False)
storage = httpx.Client(timeout=20, trust_env=False, follow_redirects=False)
def response(operation, method, path, status, **kwargs):
    r = api.request(method, path, **kwargs)
    actual = {"status": r.status_code}
    if r.status_code != status:
        detail = r.json().get("detail") if "application/json" in r.headers.get("content-type", "") else "non-JSON"
        actual["detail"] = detail if isinstance(detail, str) else [x.get("msg") for x in (detail or [])]
    check(operation, f"HTTP {status}", actual, r.status_code == status)
    return r

def proof(data, name):
    return {"file_name": name, "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "md5": base64.b64encode(hashlib.md5(data).digest()).decode()}

def put(offer, data, expected=200, headers=None):
    r = storage.put(offer['url'], content=data, headers=headers or offer['headers'])
    storage_error = None
    if r.status_code != expected:
        try:
            error = ET.fromstring(r.content)
            storage_error = {k:error.findtext(k) for k in ("Code","Message")}
        except ET.ParseError:
            storage_error = "non-XML response"
    check("对象存储 PUT", f"HTTP {expected}，不经过业务接口", {"status": r.status_code,
          "origin": str(r.request.url).split('?')[0].split('/fixture/')[0],
          "storageError": storage_error,
          "businessCredentials": "cookie" in r.request.headers or r.request.headers.get("authorization", "").startswith("Bearer ")},
          r.status_code == expected and "cookie" not in r.request.headers and not r.request.headers.get("authorization", "").startswith("Bearer "))
    return r

def decode(offer):
    return jwt.decode(offer['ticket'], "direct-upload-e2e-secret", algorithms=["HS256"], audience="object-upload")

try:
    response("隔离夹具就绪", "GET", "/healthz", 200)
    response("登录独立管理员", "POST", "/admin/api/login", 200, json={"password":"direct-upload-e2e-admin"})
    payload = b"Explicit direct upload fixture, not an executable APK.\n" * 40000
    release = response("创建测试版本", "POST", "/admin/api/releases", 201,
        json={"platform":"android","version":f"99.0.{int(time.time())%1000000}"}).json()
    path = f"/admin/api/releases/{release['id']}/artifacts"
    spec = {**proof(payload,"direct-fixture.apk"),"arch":"any"}
    # Smoke deterministic fixture failures before any browser E2E.
    for mode, status in (("fail-put", 503),("fail-complete",502)):
        response("启用确定性失败入口", "POST", "/__fixture/state", 200, json={"mode":mode})
        offer = response("失败夹具授权", "POST", path+"/uploads", 200, json=spec).json()
        if mode == "fail-put": put(offer, payload, expected=status)
        else: response("确认失败夹具冒烟", "POST",path+"/uploads/complete",status,json={"ticket":offer['ticket']})
    response("恢复正常夹具", "POST", "/__fixture/state",200,json={"mode":"normal"})
    offer = response("申请安装包直传", "POST",path+"/uploads",200,json=spec).json()
    claims = decode(offer)
    check("上传授权范围", "临时对象与最终对象不同，过期时间受限", {"backend":claims['backend'],"expires":offer['expires_in']},
          claims['source']!=claims['key'] and 0 < offer['expires_in'] <= 3600)
    response("未上传禁止确认", "POST",path+"/uploads/complete",409,json={"ticket":offer['ticket']})
    put(offer,payload)
    result=response("安装包确认入库", "POST",path+"/uploads/complete",201,json={"ticket":offer['ticket']}).json()
    artifact=result['artifacts'][0]
    check("安装包索引", "摘要、大小与存储类型一致", {"storage":artifact['storage'],"bytes":artifact['size']},
          artifact['storage']=='minio' and artifact['sha256']==spec['sha256'] and artifact['size']==len(payload))
    duplicate=response("重复确认幂等", "POST",path+"/uploads/complete",201,json={"ticket":offer['ticket']}).json()
    check("不重复创建安装包", "同一安装包 ID，只有一条记录", len(duplicate['artifacts']),
          len(duplicate['artifacts'])==1 and duplicate['artifacts'][0]['id']==artifact['id'])
    redirect=response("下载直传后的安装包", "GET",f"/api/v1/updates/download/{artifact['id']}",302)
    downloaded=storage.get(redirect.headers['location'])
    check("完整下载校验", "下载内容与原文件完全一致", {"status":downloaded.status_code,"bytes":len(downloaded.content)},
          downloaded.status_code==200 and downloaded.content==payload)
    bad=response("申请错误摘要测试", "POST",path+"/uploads",200,json=spec).json()
    bad_headers={**bad['headers'],"x-amz-meta-sha256":"0"*64}
    put(bad,payload,expected=403,headers=bad_headers)
    response("摘要头被篡改后不得确认", "POST",path+"/uploads/complete",409,json={"ticket":bad['ticket']})
    bad_md5=response("申请内容校验测试", "POST",path+"/uploads",200,json=spec).json()
    put(bad_md5,b"corrupted",expected=400)
    response("错误 MD5 后不得确认成功", "POST",path+"/uploads/complete",409,json={"ticket":bad_md5['ticket']})
    expired=decode(offer);expired['exp']=int(time.time())-1
    response("过期授权拒绝", "POST",path+"/uploads/complete",410,
             json={"ticket":jwt.encode(expired,"direct-upload-e2e-secret",algorithm="HS256")})
    h={"X-User-ID":"direct-u1","X-User-Name":"test","X-Session-ID":"direct-session"}
    meeting=response("创建独立录音会议", "POST","/api/v1/meetings",201,json={"title":"直传音频验证"},headers=h).json()
    audio=io.BytesIO()
    with wave.open(audio,'wb') as wav:
        wav.setnchannels(1);wav.setsampwidth(2);wav.setframerate(16000);wav.writeframes(b'\x00\x00'*16000)
    wav_bytes=audio.getvalue()
    audio_path=f"/api/v1/meetings/{meeting['id']}/audio"
    audio_spec={**proof(wav_bytes,"recording.wav"),"duration":1.0}
    ao=response("申请完整录音直传", "POST",audio_path+"/uploads",200,json=audio_spec,headers=h).json()
    response("其他用户无法申请", "POST",audio_path+"/uploads",404,json=audio_spec,headers={**h,"X-User-ID":"direct-u2"})
    response("票据不能跨用户确认", "POST",audio_path+"/uploads/complete",403,json={"ticket":ao['ticket']},headers={**h,"X-User-ID":"direct-u2"})
    put(ao,wav_bytes)
    confirmed_audio=response("录音确认入库", "POST",audio_path+"/uploads/complete",200,json={"ticket":ao['ticket']},headers=h).json()
    check("静音录音时长", "使用客户端采集时长，不需下载全文件探测", confirmed_audio['duration'],confirmed_audio['duration']==1.0)
    metadata=response("读取直传录音元数据", "GET",f"/api/v1/meetings/{meeting['id']}/metadata",200,headers=h).json()
    check("采集时长已持久化", "audio_duration=1.0", metadata['audio_duration'],metadata['audio_duration']==1.0)
    response("录音重复确认", "POST",audio_path+"/uploads/complete",200,json={"ticket":ao['ticket']},headers=h)
    ar=response("录音播放下载入口", "GET",audio_path,302,headers=h)
    check("录音对象可读取", "字节与原录音一致", "real MinIO GET",storage.get(ar.headers['location']).content==wav_bytes)
    io_offer=response("申请导入直传", "POST","/api/v1/jobs/import/uploads",200,
        json={**audio_spec,"title":"直传导入验证"},headers=h).json()
    resource=decode(io_offer)['resource']
    response("申请导入不创建空会议", "GET",f"/api/v1/meetings/{resource}/metadata",404,headers=h)
    put(io_offer,wav_bytes)
    job=response("导入确认创建任务", "POST","/api/v1/jobs/import/uploads/complete",202,json={"ticket":io_offer['ticket']},headers=h).json()
    duplicate_job=response("导入确认重复请求", "POST","/api/v1/jobs/import/uploads/complete",202,json={"ticket":io_offer['ticket']},headers=h).json()
    check("导入任务幂等", "只创建同一个任务", duplicate_job['id'], duplicate_job['id']==job['id'])
    pending_files=list((out/'data'/'audio').rglob('*')) if (out/'data'/'audio').exists() else []
    check("业务服务器无直传落盘", "不产生音频上传临时文件", len(pending_files),not any(p.is_file() for p in pending_files))
    requests=api.get('/__fixture/state').json()['requests']
    check("文件内容不经业务接口", "业务请求均为小 JSON，无整文件中转", max(r['contentLength'] for r in requests),
          all(r['contentLength']<20000 for r in requests))
    response("验证本地存储回退", "POST","/__fixture/state",200,json={"storage":"local"})
    fallback=response("本地存储明确返回 proxy", "POST",path+"/uploads",200,json=spec).json()
    check("本地存储兼容", "mode=proxy",fallback,fallback=={"mode":"proxy"})
    response("恢复对象存储模式", "POST","/__fixture/state",200,json={"storage":"minio"})
    print("DIRECT_UPLOAD_API_CHECKS_PASS",flush=True)
finally:
    api.close();storage.close()
