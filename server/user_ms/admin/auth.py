from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from pydantic import BaseModel

from user_ms.auth.admin import COOKIE_NAME, issue_admin_token, require_admin, verify_password
from user_ms.config import get_settings

router = APIRouter(tags=["admin-auth"])


class LoginIn(BaseModel):
    password: str


@router.post("/login")
async def login(body: LoginIn, request: Request, response: Response) -> dict:
    if not verify_password(body.password):
        raise HTTPException(401, "密码错误")
    token = issue_admin_token()
    response.set_cookie(
        COOKIE_NAME,
        token,
        max_age=get_settings().admin_token_ttl_hours * 3600,
        httponly=True,
        samesite="lax",
        secure=request.url.scheme == "https",
        path="/",
    )
    return {"token": token}


@router.post("/logout", status_code=204)
async def logout() -> Response:
    response = Response(status_code=204)
    response.delete_cookie(COOKIE_NAME, path="/")
    return response


@router.get("/me", dependencies=[Depends(require_admin)])
async def me() -> dict:
    return {"ok": True}
