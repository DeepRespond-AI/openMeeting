"""Summary templates.

Templates live in the ``summary_templates`` table and are managed from the admin web. Each one is a free-form
prompt bound to an output format; the summary pipeline picks one automatically per meeting, and clients never
see or choose templates.

The JSON files next to this module (plus any legacy custom JSON in ``$OPENMEETING_DATA_DIR/templates``) are only
the seed for the table: they are converted to prompts once, by the 0004 migration.
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import select

from meeting_ms.db.models import SummaryTemplateRow
from meeting_ms.db.session import session_factory

logger = logging.getLogger(__name__)

BUILTIN_DIR = Path(__file__).parent / "templates"
DEFAULT_SEED_ID = "standard_meeting"

FORMAT_MARKDOWN = "markdown"
FORMAT_HTML = "html"
FORMAT_MIXED = "mixed"
OUTPUT_FORMATS = (FORMAT_MARKDOWN, FORMAT_HTML, FORMAT_MIXED)


class TemplateError(Exception):
    pass


@dataclass(frozen=True)
class SummaryTemplate:
    id: str
    name: str
    description: str
    prompt: str
    output_format: str

    @classmethod
    def from_row(cls, row: SummaryTemplateRow) -> SummaryTemplate:
        return cls(row.id, row.name, row.description, row.prompt, row.output_format)


async def enabled_templates() -> list[SummaryTemplate]:
    """Enabled templates, the default one first (it is the fallback when auto-selection fails)."""
    async with session_factory()() as session:
        rows = (
            await session.execute(
                select(SummaryTemplateRow)
                .where(SummaryTemplateRow.enabled.is_(True))
                .order_by(SummaryTemplateRow.is_default.desc(), SummaryTemplateRow.created_at, SummaryTemplateRow.id)
            )
        ).scalars().all()
    return [SummaryTemplate.from_row(r) for r in rows]


# ----------------------------------------------------------------- seed (legacy section JSON → prompt)


def sections_to_prompt(raw: dict) -> str:
    """Render a legacy section-based template as a plain prompt an admin can edit."""
    lines = [
        "Write the report in GitHub-flavored Markdown. Start with a level-1 heading "
        "`# <concise, descriptive meeting title>`, then write exactly these sections, in this order, each as a "
        "level-2 heading:",
        "",
    ]
    for section in raw.get("sections") or []:
        title, instruction = section.get("title"), section.get("instruction")
        if not title or not instruction:
            raise TemplateError("Each template section needs a title and an instruction")
        lines.append(f"## {title}")
        lines.append(instruction.rstrip(". ") + ".")
        fmt = section.get("format")
        if fmt == "list":
            lines.append("Write this section as a bulleted list.")
        elif fmt == "paragraph":
            lines.append("Write this section as prose paragraphs.")
        elif fmt == "string":
            lines.append("Write this section as a single short line.")
        item_format = section.get("item_format") or section.get("example_item_format")
        if item_format:
            lines.append(f"Items in this section should follow the format: `{item_format}`")
        lines.append("")
    return "\n".join(lines).strip()


def seed_rows(extra_dir: Path | None = None) -> list[dict]:
    """Seed rows built from the bundled JSON templates (custom JSON in ``extra_dir`` overrides by id)."""
    files: dict[str, Path] = {p.stem: p for p in sorted(BUILTIN_DIR.glob("*.json"))}
    if extra_dir is not None and extra_dir.is_dir():
        files.update({p.stem: p for p in sorted(extra_dir.glob("*.json"))})
    rows = []
    for template_id, path in files.items():
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
            name, description = (raw.get("name") or "").strip(), (raw.get("description") or "").strip()
            if not name or not description:
                raise TemplateError("name and description are required")
            prompt = sections_to_prompt(raw)
        except (ValueError, TemplateError) as exc:
            logger.warning("Skipping summary template seed %s: %s", path, exc)
            continue
        rows.append({
            "id": template_id[:64], "name": name[:200], "description": description, "prompt": prompt,
            "output_format": FORMAT_MARKDOWN, "enabled": True, "is_default": template_id == DEFAULT_SEED_ID,
        })
    return rows
