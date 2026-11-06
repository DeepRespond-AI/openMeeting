"""Deterministic external HTTP/TLS/WS vendor on the edge network only; never a production route."""
import asyncio
import hashlib
import json
import os
from pathlib import Path
import xml.etree.ElementTree as ET

from fastapi import FastAPI, Request, WebSocket
from fastapi.responses import JSONResponse, Response
import uvicorn

OUT=Path('/acceptance')
app=FastAPI()
state={'fail':False,'delay':0}
objects={}


@app.post('/control')
async def control(request:Request):
    patch=await request.json()
    state.update({k:patch[k] for k in state if k in patch})
    return state


@app.websocket('/ws')
async def websocket(ws:WebSocket):
    await ws.accept()
    try:
        while True:
            message=await ws.receive()
            if message.get('type')=='websocket.disconnect':break
            if message.get('bytes') is not None:await ws.send_bytes(message['bytes'])
            else:await ws.send_text(message['text'])
    except Exception:
        pass


@app.api_route('/{path:path}',methods=['GET','POST','PUT','DELETE','HEAD'])
async def vendor(path:str,request:Request):
    body=await request.body()
    # Evidence contains no provider keys, signatures, SMS recipients or raw audio payload.
    record={'method':request.method,'path':request.url.path,'bytes':len(body),
            'proxy_header_leaked':'proxy-authorization' in request.headers,
            'authorization_present':'authorization' in request.headers}
    with (OUT/'vendor-requests.jsonl').open('a',encoding='utf8') as f:f.write(json.dumps(record)+'\n')
    if state['delay']:await asyncio.sleep(min(state['delay'],5))
    if state['fail']:return JSONResponse({'error':'deterministic vendor failure'},status_code=503)
    if path.endswith('/models'):
        return {'data':[{'id':'gateway-fixture-model'}]}
    if path.endswith('/chat/completions'):
        return {'choices':[{'message':{'content':'OK：'+('请求已经通过统一出站网关并保持 TLS 校验。'*40)}}]}
    if path.endswith('/audio/transcriptions'):
        return {'text':'通过网关的云端识别夹具结果'}
    if path.endswith('/token'):
        return {'access_token':'fixture-platform-token','expires_in':7200,'application':'fixture-app'}
    if path.endswith('/login-tickets'):
        return {'ticket':'fixture-login-ticket','expires_in':300,'user_created':True}
    if request.method=='POST' and not path and 'delete' in request.query_params:
        keys=[node.text for node in ET.fromstring(body).iter() if node.tag.endswith('Key')]
        for key in keys:objects.pop(key,None)
        return Response('<DeleteResult>'+''.join('<Deleted><Key>'+key+'</Key></Deleted>' for key in keys)+'</DeleteResult>',media_type='application/xml',headers={'x-oss-request-id':'fixture-oss'})
    if request.method=='POST' and not path:
        return {'Code':'OK','Message':'OK','RequestId':'fixture-sms-request','BizId':'fixture-sms'}
    headers={'x-oss-request-id':'fixture-oss','ETag':'"'+hashlib.md5(body).hexdigest()+'"'}
    if request.method=='PUT':objects[path]=body;return Response(status_code=200,headers=headers)
    if request.method=='DELETE':objects.pop(path,None);return Response(status_code=204,headers=headers)
    if request.method=='GET' and not path:
        prefix=request.query_params.get('prefix','')
        content=''.join('<Contents><Key>'+key+'</Key><LastModified>2026-10-24T00:00:00.000Z</LastModified><ETag>fixture</ETag><Type>Normal</Type><Size>'+str(len(value))+'</Size><StorageClass>Standard</StorageClass></Contents>' for key,value in objects.items() if key.startswith(prefix))
        return Response('<ListBucketResult><Name>fixture-bucket</Name><Prefix>'+prefix+'</Prefix><IsTruncated>false</IsTruncated>'+content+'</ListBucketResult>',media_type='application/xml',headers=headers)
    if path in objects:return Response(objects[path],headers=headers)
    return Response(b'fixture-download-bytes',headers=headers)


async def main():
    configs=[uvicorn.Config(app,host='0.0.0.0',port=4080,log_level='warning'),
             uvicorn.Config(app,host='0.0.0.0',port=4081,ssl_certfile='/acceptance/vendor-cert.pem',ssl_keyfile='/acceptance/vendor-key.pem',log_level='warning')]
    await asyncio.gather(*(uvicorn.Server(cfg).serve() for cfg in configs))


if __name__=='__main__':asyncio.run(main())
