"""Isolated E2E backend: real service routers, Pydantic, migrations and PostgreSQL.

Only gateway identity and deterministic save failure/delay are fixtures. No SMS or IM.
Requires the disposable test container described by field-limits.mjs/report.
"""
import asyncio
import os
from contextlib import asynccontextmanager

os.environ.update(OPENMEETING_ENV='test', OPENMEETING_EGRESS_PROXY_URL='', OPENMEETING_IM_ENABLED='false',
                  OPENMEETING_SECRET_KEY='field-limit-test-only', OPENMEETING_INTERNAL_SERVICE_TOKEN='',
                  OPENMEETING_STT_BASE_URL='http://127.0.0.1:9',
                  OPENMEETING_DATA_DIR=os.path.abspath('../.artifacts/field-limits/api-data'))

from asgi_lifespan import LifespanManager
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from sqlalchemy.dialects.postgresql import insert
from meeting_ms.config import get_settings as meeting_settings
from user_ms.config import get_settings as user_settings
from meeting_ms.main import app as meeting_app
from user_ms.main import app as user_app
from user_ms.db.models import User
from user_ms.db.session import session_factory
from user_ms.utils import utcnow

meeting_settings().database_url = 'postgresql+asyncpg://fieldtest:fieldtest@127.0.0.1:55462/field_meeting'
user_settings().database_url = 'postgresql+asyncpg://fieldtest:fieldtest@127.0.0.1:55462/field_user'
gate = asyncio.Event()
mode = 'normal'


@asynccontextmanager
async def lifespan(app):
    async with LifespanManager(meeting_app), LifespanManager(user_app):
        async with session_factory()() as session:
            await session.execute(insert(User).values(id='field-user', phone='13800139999', name='测试用户',
                                                      disabled=False, created_at=utcnow()).on_conflict_do_nothing())
            await session.commit()
        yield


app = FastAPI(lifespan=lifespan)


@app.middleware('http')
async def deterministic_save(request: Request, call_next):
    if request.method == 'PATCH' and request.url.path.startswith(('/meeting/api/', '/user/api/')):
        if mode == 'error':
            return JSONResponse({'detail': '测试夹具：保存失败，请重试'}, status_code=503)
        if mode == 'loading':
            await asyncio.wait_for(gate.wait(), timeout=20)
    return await call_next(request)


@app.post('/fixture/mode/{value}')
async def set_mode(value: str):
    global mode
    mode = value
    if value == 'loading':
        gate.clear()
    else:
        gate.set()
    return {'mode': mode}


app.mount('/meeting', meeting_app)
app.mount('/user', user_app)
