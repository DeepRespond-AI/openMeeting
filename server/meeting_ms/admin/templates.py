"""Summary template management. The summary pipeline auto-selects among the enabled templates."""
from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from meeting_ms.db.models import SummaryTemplateRow
from meeting_ms.db.session import get_session
from meeting_ms.utils import iso, new_uuid, utcnow

router = APIRouter(prefix="/summary-templates", tags=["admin-templates"])


class TemplateIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1)
    prompt: str = Field(min_length=1)
    output_format: Literal["markdown", "html", "mixed"] = "markdown"
    enabled: bool = True
    is_default: bool = False


def template_dict(t: SummaryTemplateRow) -> dict:
    return {
        "id": t.id,
        "name": t.name,
        "description": t.description,
        "prompt": t.prompt,
        "output_format": t.output_format,
        "enabled": t.enabled,
        "is_default": t.is_default,
        "created_at": iso(t.created_at),
        "updated_at": iso(t.updated_at),
    }


async def _get(session: AsyncSession, template_id: str) -> SummaryTemplateRow:
    t = await session.get(SummaryTemplateRow, template_id)
    if t is None:
        raise HTTPException(404, "总结模板不存在")
    return t


def _apply(t: SummaryTemplateRow, body: TemplateIn) -> None:
    name, description, prompt = body.name.strip(), body.description.strip(), body.prompt.strip()
    if not name or not description or not prompt:
        raise HTTPException(422, "名称、适用场景说明和提示词都不能为空")
    t.name, t.description, t.prompt = name, description, prompt
    t.output_format = body.output_format
    t.enabled = body.enabled
    t.is_default = body.is_default and body.enabled
    t.updated_at = utcnow()


async def _finish(session: AsyncSession, t: SummaryTemplateRow) -> None:
    """Keep at most one default and at least one enabled template, then commit."""
    await session.flush()
    if t.is_default:
        await session.execute(
            update(SummaryTemplateRow).where(SummaryTemplateRow.id != t.id).values(is_default=False)
        )
    enabled = (
        await session.execute(select(func.count()).where(SummaryTemplateRow.enabled.is_(True)))
    ).scalar_one()
    if enabled == 0:
        await session.rollback()
        raise HTTPException(400, "至少需要保留一个启用的模板")
    await session.commit()


@router.get("")
async def list_templates(session: AsyncSession = Depends(get_session)) -> list[dict]:
    rows = (
        await session.execute(
            select(SummaryTemplateRow).order_by(SummaryTemplateRow.created_at, SummaryTemplateRow.id)
        )
    ).scalars().all()
    return [template_dict(t) for t in rows]


@router.post("")
async def create_template(body: TemplateIn, session: AsyncSession = Depends(get_session)) -> dict:
    now = utcnow()
    t = SummaryTemplateRow(id=new_uuid(), created_at=now)
    _apply(t, body)
    session.add(t)
    await _finish(session, t)
    return template_dict(t)


@router.put("/{template_id}")
async def update_template(template_id: str, body: TemplateIn, session: AsyncSession = Depends(get_session)) -> dict:
    t = await _get(session, template_id)
    _apply(t, body)
    await _finish(session, t)
    return template_dict(t)


@router.delete("/{template_id}", status_code=204)
async def delete_template(template_id: str, session: AsyncSession = Depends(get_session)) -> Response:
    t = await _get(session, template_id)
    await session.delete(t)
    await session.flush()
    remaining = (
        await session.execute(select(func.count()).where(SummaryTemplateRow.enabled.is_(True)))
    ).scalar_one()
    if remaining == 0:
        await session.rollback()
        raise HTTPException(400, "至少需要保留一个启用的模板")
    await session.commit()
    return Response(status_code=204)
