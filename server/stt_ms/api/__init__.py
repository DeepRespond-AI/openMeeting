from fastapi import APIRouter, Depends

from stt_ms.api import admin_stt, internal
from stt_ms.api.deps import require_internal

# Admin routes (gateway has verified the admin JWT; the internal token guards direct access).
admin_router = APIRouter(prefix="/admin/api", dependencies=[Depends(require_internal)])
admin_router.include_router(admin_stt.router)

# Internal API for meeting_ms — same token guard, mounted at /internal.
internal_router = APIRouter(dependencies=[Depends(require_internal)])
internal_router.include_router(internal.router, prefix="/internal", tags=["internal"])

router = APIRouter()
router.include_router(admin_router)
router.include_router(internal_router)
