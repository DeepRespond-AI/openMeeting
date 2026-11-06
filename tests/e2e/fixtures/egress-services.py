"""Isolated Docker acceptance launcher; production handlers and network policy stay real."""
import argparse
import importlib
import json
import os
from pathlib import Path
import ssl
import sys

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'server'))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--service',choices=['gateway','user','meeting','stt'],required=True)
    service=parser.parse_args().service
    os.environ.update(OPENMEETING_ENV='test',OPENMEETING_SECRET_KEY='egress-isolated-secret',OPENMEETING_ADMIN_PASSWORD='EgressTest123!',
        OPENMEETING_INTERNAL_SERVICE_TOKEN='egress-fixture-internal',OPENMEETING_EGRESS_PROXY_URL='http://gateway_ms:39111',
        OPENMEETING_GATEWAY_MS_URL='http://gateway_ms:39110',OPENMEETING_USER_MS_URL='http://user_ms:39113',
        OPENMEETING_MEETING_MS_URL='http://meeting_ms:39107',OPENMEETING_STT_MS_URL='http://stt_ms:39109',
        OPENMEETING_DATABASE_URL=f"postgresql+asyncpg://openmeeting:egress-db-test@{'user' if service=='gateway' else service}-postgres:5432/openmeeting_{'user' if service=='gateway' else service}",
        OPENMEETING_DATA_DIR='/data',OPENMEETING_AUTO_MIGRATE='true',OPENMEETING_IM_ENABLED='false',
        REQUESTS_CA_BUNDLE='/acceptance/vendor-cert.pem',SSL_CERT_FILE='/acceptance/vendor-cert.pem')
    os.chdir('/acceptance')
    module=importlib.import_module(service+'_ms.config');module.Settings.model_config['env_file']=None
    # Trust the fixture CA, with verification enabled; do not modify any production trust code.
    from service_net import egress
    original_options=egress.proxy_options
    def options(settings):
        return {**original_options(settings),'verify':ssl.create_default_context(cafile='/acceptance/vendor-cert.pem')}
    egress.proxy_options=options
    original_requests=egress.configure_requests
    def configure_requests(session,settings):
        original_requests(session,settings);session.verify='/acceptance/vendor-cert.pem';return session
    egress.configure_requests=configure_requests
    app=importlib.import_module(service+'_ms.main').app
    if service=='gateway':
        from fastapi import Request
        settings=module.get_settings();settings.egress_enabled=True
        settings.egress_allowed_hosts=['vendor','*.vendor'];settings.egress_private_hosts=['vendor','fixture-bucket.vendor']
        settings.egress_allowed_ports=[4080,4081]
        @app.post('/__test__/control')
        async def control(request:Request):
            payload=await request.json();fault=payload.get('proxy_fault','normal')
            proxy=app.state.egress_proxy
            if fault=='down':await proxy.close()
            else:
                settings.egress_allowed_hosts=[] if fault=='deny' else ['vendor','*.vendor']
                if not proxy.server.is_serving():await proxy.start()
            return {'proxy_fault':fault}
        @app.middleware('http')
        async def evidence(request:Request,call_next):
            response=await call_next(request)
            if request.url.path.startswith('/internal/'):
                with Path('/acceptance/internal-requests.jsonl').open('a',encoding='utf8') as stream:
                    stream.write(json.dumps({'method':request.method,'path':request.url.path,'status':response.status_code})+'\n')
            return response
    import uvicorn
    uvicorn.run(app,host='0.0.0.0',port={'gateway':39110,'user':39113,'meeting':39107,'stt':39109}[service],log_level='info',timeout_graceful_shutdown=3)


if __name__=='__main__':main()
