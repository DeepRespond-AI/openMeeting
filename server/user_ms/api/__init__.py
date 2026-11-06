from fastapi import APIRouter, Depends

from user_ms.api import internal, internal_rtc, internal_meeting_chat
from user_ms.api.deps import require_client, require_internal
from user_ms.api.v1 import auth, client, im, updates
from user_ms.auth.admin import require_admin

router = APIRouter(dependencies=[Depends(require_internal)])

# Client endpoints under /api/v1. Login/registration and upgrade checks are public;
# everything else requires a gateway-resolved identity.
v1 = APIRouter(prefix="/api/v1")
v1.include_router(auth.public_router)
v1.include_router(updates.public_router)
_protected = APIRouter(dependencies=[Depends(require_client)])
for module in (auth, client, im):
    _protected.include_router(module.router)
v1.include_router(_protected)

# Admin endpoints under /admin/api. The gateway has already verified the admin JWT; user_ms
# re-checks it locally (it holds the secret anyway) so admin routes stay protected even if the
# internal token is misconfigured. login/logout stay public for the initial sign-in.
admin = APIRouter(prefix="/admin/api")
from user_ms.admin import auth as admin_auth  # noqa: E402
from user_ms.admin import auth_settings, releases, users  # noqa: E402

admin.include_router(admin_auth.router)
_admin_protected = APIRouter(dependencies=[Depends(require_admin)])
for module in (auth_settings, releases, users):
    _admin_protected.include_router(module.router)
admin.include_router(_admin_protected)

router.include_router(v1)
router.include_router(admin)
router.include_router(internal.router)
router.include_router(internal_rtc.router)
router.include_router(internal_meeting_chat.router)
