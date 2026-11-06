from fastapi import APIRouter

from gateway_ms.api import gateway

router = APIRouter()
router.include_router(gateway.router)
