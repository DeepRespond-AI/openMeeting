"""Exercise production adapters and real SDK transports inside network-isolated service containers."""
import argparse
import asyncio
import importlib
import json
import os
from pathlib import Path
import socket
import ssl
import sys
import tempfile

sys.path.insert(0,'/workspace/server')


async def main():
    parser=argparse.ArgumentParser();parser.add_argument('--service',required=True);parser.add_argument('--vendor-ip',required=True)
    args=parser.parse_args();service=args.service
    settings=importlib.import_module(service+'_ms.config').get_settings()
    settings.egress_proxy_url='http://gateway_ms:39111';settings.internal_service_token='egress-fixture-internal'
    from service_net import egress
    original=egress.proxy_options
    egress.proxy_options=lambda config:{**original(config),'verify':ssl.create_default_context(cafile='/acceptance/vendor-cert.pem')}
    original_requests=egress.configure_requests
    def configured(session,config):
        original_requests(session,config);session.verify='/acceptance/vendor-cert.pem';return session
    egress.configure_requests=configured

    def emit(operation,actual):
        print(json.dumps({'operation':operation,'expected':'经网关成功，或绕过网关被网络层拒绝','actual':actual,'pass':True,'screenshot':None},ensure_ascii=False),flush=True)
    try:
        with socket.create_connection((args.vendor_ip,4080),timeout=2):
            raise AssertionError('Business container bypassed the gateway')
    except OSError:
        emit(service+' 外网直连禁止','直接连接 edge 网络的供应商 IP 被拒绝')
    with socket.create_connection((service+'-postgres',5432),timeout=2):
        emit(service+' 自有数据库可达','仅本服务数据库的内部连接可用')
    async with egress.async_client(settings) as client:
        response=await client.get('https://vendor:4081/transport')
        assert response.status_code==200
    emit(service+' HTTPS 出站','真实 HTTPX 经 CONNECT 和证书校验成功')
    if service=='user':
        settings.im_enabled=True;settings.im_base_url='https://vendor:4081';settings.im_org_name='org';settings.im_app_name='app'
        settings.im_client_id='fixture-client';settings.im_client_secret='fixture-secret'
        from user_ms.infrastructure import im_client
        try:
            ticket=await im_client.issue_login_ticket('fixture-user')
            assert ticket['ticket']=='fixture-login-ticket'
            emit('IM 真实 SDK 换票','真实 AsyncDRClient 完成 App Token 与用户票据请求，URL 保持供应商地址')
        finally:await im_client.aclose_client()
        from user_ms.auth.aliyun_sms import send_sms
        sms=await send_sms(endpoint='vendor:4081',access_key_id='fixture-id',access_key_secret='fixture-secret',phone='19900000000',sign_name='fixture',template_code='fixture',template_param={'code':'123456'})
        assert sms.ok
        emit('短信签名请求','实际生产签名逻辑经网关发送至隔离供应商，无真实短信发送')
        from user_ms.storage.oss import OssConfig,OssStore
        store=OssStore(OssConfig('vendor:4081','cn-fixture','fixture-bucket','fixture-id','fixture-secret','acceptance/'))
        with tempfile.TemporaryDirectory() as directory:
            source=Path(directory)/'upload';source.write_bytes(b'release-through-egress')
            target=Path(directory)/'download';key=store.key('release')
            await store.upload(source,key,None);await store.download_to(key,target)
            assert target.read_bytes()==source.read_bytes()
            await store.delete_prefix('acceptance/')
        emit('发布包 OSS 真实 SDK','oss2 签名上传、下载与删除经过验证 TLS 的 CONNECT 隧道')
    elif service=='meeting':
        from meeting_ms.llm.client import LlmConfig,chat_completion,list_models
        assert await list_models('https://vendor:4081/v1','fixture-key')==['gateway-fixture-model']
        assert 'OK' in (await chat_completion(LlmConfig('https://vendor:4081/v1','gateway-fixture-model','fixture-key'),'test','test')).content
        emit('LLM 生产适配器','获取模型列表和生成请求均经网关 HTTPS 隧道')
        from meeting_ms.storage.oss import OssAudioStore,OssConfig
        await OssAudioStore(OssConfig('vendor:4081','cn-fixture','fixture-bucket','fixture-id','fixture-secret','acceptance/')).test()
        emit('录音 OSS 真实 SDK','生产 OSS 连通性测试实际完成签名 PUT / GET / DELETE')
    elif service=='stt':
        import numpy as np
        from stt_ms.stt.cloud_engine import CloudConfig,CloudEngine
        result=await asyncio.to_thread(CloudEngine(CloudConfig('openai','https://vendor:4081/v1','fixture-asr','fixture-key')).transcribe,np.zeros(160,dtype=np.float32),'zh')
        assert '网关' in result.text
        emit('云端 ASR 生产适配器','实际 multipart WAV 上传经网关；供应商推理为确定性夹具')
        os.environ['SSL_CERT_FILE']=os.environ['REQUESTS_CA_BUNDLE']='/acceptance/vendor-cert.pem'
        egress.configure_sdk_environment(settings)
        def websocket():
            import websocket
            connection=websocket.create_connection('wss://vendor:4081/ws',sslopt={'ca_certs':'/acceptance/vendor-cert.pem'},timeout=5)
            try:
                connection.send('ws-through-egress');assert connection.recv()=='ws-through-egress'
            finally:connection.close()
        await asyncio.to_thread(websocket)
        emit('云 ASR WebSocket 传输','DashScope 所用 websocket-client 实际经环境代理完成 WSS 双向通信')
        def download_clients():
            from huggingface_hub.utils import get_session
            response=get_session().get('https://vendor:4081/model-file');assert response.status_code==200
            from modelscope.hub.api import HubApi
            api=HubApi();response=api.session.get('https://vendor:4081/model-file');assert response.status_code==200
        await asyncio.to_thread(download_clients)
        emit('模型下载 SDK HTTP 客户端','Hugging Face 与 ModelScope 的实际下载 HTTP 客户端经代理取回测试文件；未下载模型权重')


if __name__=='__main__':asyncio.run(main())
