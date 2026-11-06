from fastapi import APIRouter, Depends

from meeting_ms.api import internal
from meeting_ms.api.deps import require_client, require_internal
from meeting_ms.api.v1 import audio, client, jobs, meetings, recording, rooms, rooms_ws, scheduled, screen_share, summaries, transcribe

# Client endpoints under /api/v1 — the gateway has already authenticated the session.
v1 = APIRouter(prefix="/api/v1", dependencies=[Depends(require_client)])
for module in (client, meetings, scheduled, rooms, transcribe, audio, jobs, summaries, screen_share, recording):
    v1.include_router(module.router)

# Admin endpoints under /admin/api — the gateway has already verified the admin JWT.
admin = APIRouter(prefix="/admin/api")
from meeting_ms.admin import dashboard, data, llm, object_storage, storage, templates  # noqa: E402

for module in (dashboard, llm, templates, object_storage, storage, data):
    admin.include_router(module.router)

http_router = APIRouter(dependencies=[Depends(require_internal)])
http_router.include_router(v1)
http_router.include_router(admin)
http_router.include_router(internal.router)

# Room signaling WS — excluded from require_internal (a WebSocket is not a Request);
# it authenticates the gateway-injected headers itself (rooms_ws.py).
ws_router = APIRouter()
ws_router.include_router(rooms_ws.router)

router = APIRouter()
router.include_router(http_router)
router.include_router(ws_router)
