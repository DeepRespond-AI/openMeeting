"""Real four-service acceptance stack. Fault injection exists only in this loopback launcher."""
import argparse
import asyncio
from contextlib import asynccontextmanager
import importlib
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'server'))
OUT = Path(os.environ.get('GATEWAY_TEST_OUTPUT', ROOT / '.artifacts/internal-gateway-routing'))
OUT.mkdir(parents=True, exist_ok=True)
PORTS = {'gateway': 39710, 'user': 39713, 'meeting': 39707, 'stt': 39709}
DB_PORTS = {'gateway': 55451, 'user': 55451, 'meeting': 55452, 'stt': 55453}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--service', choices=PORTS, required=True)
    args = parser.parse_args()
    service = args.service
    # Do not inherit real SMS, cloud credentials or a business database from shell/.env.
    for key in list(os.environ):
        if key.startswith('OPENMEETING_'):
            del os.environ[key]
    os.environ.update(
        OPENMEETING_ENV='test', OPENMEETING_SECRET_KEY='gateway-routing-isolated-test-key',
        OPENMEETING_ADMIN_PASSWORD='GatewayTest123!', OPENMEETING_INTERNAL_SERVICE_TOKEN='gateway-acceptance-internal',
        OPENMEETING_DATABASE_URL=f"postgresql+asyncpg://openmeeting:gateway-test-db@127.0.0.1:{DB_PORTS[service]}/openmeeting_{'user' if service == 'gateway' else service}",
        OPENMEETING_GATEWAY_MS_URL=f"http://127.0.0.1:{PORTS['gateway']}",
        OPENMEETING_USER_MS_URL=f"http://127.0.0.1:{PORTS['user']}",
        OPENMEETING_MEETING_MS_URL=f"http://127.0.0.1:{PORTS['meeting']}",
        OPENMEETING_STT_MS_URL=f"http://127.0.0.1:{PORTS['stt']}",
        OPENMEETING_DATA_DIR=str(OUT / 'server-data' / service),
        OPENMEETING_IM_ENABLED='false', OPENMEETING_AUTO_MIGRATE='true',
    )
    # Use no local .env at all, including in module-level config initialization.
    os.chdir(OUT)
    module = importlib.import_module(service + '_ms.config')
    module.Settings.model_config['env_file'] = None
    from fastapi import Request
    from fastapi.responses import JSONResponse
    app = importlib.import_module(service + '_ms.main').app
    if service == 'gateway':
        import httpx
        state = {'outage': False, 'delay': 0, 'list_error': False}
        class ControlledTransport(httpx.AsyncBaseTransport):
            def __init__(self):
                self.real = httpx.AsyncHTTPTransport()

            async def handle_async_request(self, request):
                if state['outage'] and request.url.port == PORTS['meeting'] and request.method == 'DELETE':
                    raise httpx.ConnectError('Deterministic meeting downstream outage', request=request)
                return await self.real.handle_async_request(request)

            async def aclose(self):
                await self.real.aclose()

        original_lifespan = app.router.lifespan_context
        @asynccontextmanager
        async def lifespan(app):
            async with original_lifespan(app):
                await app.state.http_client.aclose()
                async with httpx.AsyncClient(transport=ControlledTransport(), timeout=30, trust_env=False) as client:
                    app.state.http_client = client
                    yield
        app.router.lifespan_context = lifespan

        @app.post('/__test__/control')
        async def control(request: Request):
            payload = await request.json()
            state.update({k: payload[k] for k in state if k in payload})
            return state

        @app.middleware('http')
        async def evidence(request: Request, call_next):
            if request.url.path == '/admin/api/users' and request.method == 'GET':
                if state['delay']:
                    await asyncio.sleep(min(10, state['delay']))
                if state['list_error']:
                    return JSONResponse({'detail': '用户服务暂不可用，请重试'}, status_code=502)
            response = await call_next(request)
            if request.url.path.startswith('/internal/'):
                with (OUT / 'gateway-requests.jsonl').open('a', encoding='utf-8') as stream:
                    stream.write(json.dumps({'method': request.method, 'path': request.url.path,
                                             'status': response.status_code}, ensure_ascii=False) + '\n')
            return response
    import uvicorn
    uvicorn.run(app, host='127.0.0.1', port=PORTS[service], log_level='info', timeout_graceful_shutdown=3)


if __name__ == '__main__':
    main()
