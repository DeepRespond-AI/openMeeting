"""Summary generation pipeline (port of frontend/src-tauri/src/summary/processor.rs)."""
from __future__ import annotations

import html
import json
import logging
import math
import re
from dataclasses import dataclass

from meeting_ms.llm.client import LlmConfig, LlmError, chat_completion
from meeting_ms.summary.templates import FORMAT_HTML, SummaryTemplate

logger = logging.getLogger(__name__)

THINK_ENVELOPE_RE = re.compile(r"<think(?:ing)?(?:\s+[^>]*)?>.*?</think(?:ing)?\s*>", re.IGNORECASE | re.DOTALL)
THINK_MARKER_RE = re.compile(r"</?think(?:ing)?(?:\s+[^>]*)?>", re.IGNORECASE | re.DOTALL)

MAX_CHUNK_ATTEMPTS = 2
# How much of the (possibly pre-summarized) transcript the template selector sees.
SELECTION_EXCERPT_CHARS = 12000


class SummaryError(Exception):
    pass


@dataclass
class CleanedMarkdown:
    markdown: str
    reasoning_stripped: bool


def clean_llm_markdown(raw: str) -> CleanedMarkdown:
    visible = THINK_ENVELOPE_RE.sub("", raw)
    reasoning_stripped = visible != raw
    trimmed = visible.strip()
    markdown = trimmed
    for prefix in ("```markdown\n", "```html\n", "```\n", "```markdown\r\n", "```html\r\n", "```\r\n"):
        if trimmed.startswith(prefix) and trimmed.endswith("```") and len(trimmed) >= len(prefix) + 3:
            markdown = trimmed[len(prefix) : len(trimmed) - 3].strip()
            break
    if THINK_MARKER_RE.search(markdown):
        logger.warning("LLM output contains an unterminated reasoning marker")
    return CleanedMarkdown(markdown=markdown, reasoning_stripped=reasoning_stripped)


def contains_reasoning_marker(markdown: str) -> bool:
    return THINK_MARKER_RE.search(markdown) is not None


def require_visible_markdown(stage: str, cleaned: CleanedMarkdown) -> None:
    if contains_reasoning_marker(cleaned.markdown):
        raise SummaryError(f"{stage} contained an unterminated reasoning marker")
    if not cleaned.markdown:
        raise SummaryError(f"{stage} returned no visible summary content after reasoning removal")


def rough_token_count(s: str) -> int:
    return math.ceil(len(s) * 0.35)


def chunk_text(text: str, chunk_size_tokens: int, overlap_tokens: int) -> list[str]:
    """Overlapping character chunks sized by token estimate, preferring sentence/word boundaries."""
    if not text or chunk_size_tokens <= 0:
        return []
    chars_per_token = 1.0 / 0.35
    chunk_chars = math.ceil(chunk_size_tokens * chars_per_token)
    overlap_chars = math.ceil(overlap_tokens * chars_per_token)
    total = len(text)
    if total <= chunk_chars:
        return [text]
    chunks: list[str] = []
    start = 0
    while start < total:
        end = min(start + chunk_chars, total)
        emitted_end = end
        if end < total:
            window = text[start:end]
            boundary = None
            sentence = window.rfind(". ")
            if sentence != -1 and sentence + 2 > overlap_chars:
                boundary = sentence + 2
            else:
                word = window.rfind(" ")
                if word != -1 and word + 1 > overlap_chars:
                    boundary = word + 1
            if boundary is not None:
                emitted_end = start + boundary
        chunks.append(text[start:emitted_end])
        if emitted_end >= total:
            break
        start = max(emitted_end - overlap_chars, start + 1)
    return chunks


TAG_RE = re.compile(r"<[^>]+>")
STYLE_RE = re.compile(r"<style\b[^>]*>.*?</style\s*>", re.IGNORECASE | re.DOTALL)
HTML_HEAD_RE = re.compile(r"<head\b[^>]*>(.*?)</head\s*>", re.IGNORECASE | re.DOTALL)
HTML_BODY_RE = re.compile(r"<body\b[^>]*>(.*?)</body\s*>", re.IGNORECASE | re.DOTALL)
HTML_DOC_NOISE_RE = re.compile(r"<!DOCTYPE[^>]*>|</?html\b[^>]*>|<head\b[^>]*>.*?</head\s*>", re.IGNORECASE | re.DOTALL)
# A leading `<h1>`, possibly after the `<style>` blocks kept by normalize_html_document.
LEADING_H1_RE = re.compile(
    r"\s*((?:<style\b[^>]*>.*?</style\s*>\s*)*)<h1\b[^>]*>(.*?)</h1\s*>", re.IGNORECASE | re.DOTALL
)


def normalize_html_document(content: str) -> str:
    """Reduce a full HTML document to its body fragment, keeping the `<style>` blocks from its `<head>`."""
    head = HTML_HEAD_RE.search(content)
    styles = "\n".join(STYLE_RE.findall(head.group(1))) if head else ""
    body = HTML_BODY_RE.search(content)
    fragment = body.group(1).strip() if body else HTML_DOC_NOISE_RE.sub("", content).strip()
    return f"{styles}\n{fragment}" if styles else fragment


def extract_meeting_name_from_markdown(markdown: str) -> str | None:
    first_line = markdown.lstrip().split("\n", 1)[0]
    if first_line.startswith("# "):
        return first_line.removeprefix("# ").lstrip("# ").strip() or None
    return None


def extract_meeting_name(content: str, output_format: str) -> str | None:
    """Title from the report's leading heading (`# ...` or `<h1>...</h1>`), if it starts with one."""
    match = LEADING_H1_RE.match(content)
    if match:
        name = html.unescape(TAG_RE.sub("", match.group(2))).strip()
        return name or None
    if output_format == FORMAT_HTML:
        return None
    return extract_meeting_name_from_markdown(content)


def strip_leading_html_title(content: str) -> str:
    match = LEADING_H1_RE.match(content)
    if not match:
        return content
    styles = match.group(1).strip()
    rest = content[match.end():].lstrip()
    return f"{styles}\n{rest}" if styles else rest


# Long transcripts are condensed before the final report. These intermediate prompts keep the transcript's own
# language so they do not steer the report; the report itself is governed by the template prompt alone.
def build_chunk_summary_user_prompt(chunk: str) -> str:
    return (
        "Provide a concise but comprehensive summary of the following transcript chunk, written in the same language "
        "as the transcript. Capture all key points, decisions, action items, and mentioned individuals. Do not include "
        "reasoning, self-correction, or meta-commentary — output only the summary content.\n\n"
        f"<transcript_chunk>\n{chunk}\n</transcript_chunk>"
    )


def build_combine_summary_user_prompt(combined: str) -> str:
    return (
        "The following are consecutive summaries of a meeting. Combine them into a single, coherent, and detailed "
        "narrative summary, written in the same language as the summaries, that retains all important details, "
        "organized logically. Do not include reasoning, self-correction, or meta-commentary — output only the summary "
        "content.\n\n"
        f"<summaries>\n{combined}\n</summaries>"
    )


TEMPLATE_SELECTION_SYSTEM_PROMPT = (
    "You choose the report template that best fits a meeting. Read the template descriptions and the meeting "
    "content, then reply with JSON only, no other text: {\"template\": <number of the best template>}"
)


def build_template_selection_user_prompt(templates: list[SummaryTemplate], content: str, custom_prompt: str) -> str:
    listing = "\n".join(
        f"{i}. {t.name}\n   {t.description.strip()}" for i, t in enumerate(templates, start=1)
    )
    excerpt = content[:SELECTION_EXCERPT_CHARS]
    prompt = f"<templates>\n{listing}\n</templates>\n\n<meeting_content>\n{excerpt}\n</meeting_content>"
    if custom_prompt:
        prompt += f"\n\n<user_context>\n{custom_prompt}\n</user_context>"
    return prompt


_SELECTION_NUMBER_RE = re.compile(r"\d+")


def parse_template_selection(reply: str, count: int) -> int | None:
    """0-based index of the chosen template, or None when the reply is unusable."""
    text = clean_llm_markdown(reply).markdown
    candidate: object = None
    match = re.search(r"\{.*?\}", text, re.DOTALL)
    if match:
        try:
            candidate = json.loads(match.group(0)).get("template")
        except (ValueError, AttributeError):
            candidate = None
    if candidate is None:
        number = _SELECTION_NUMBER_RE.search(text)
        candidate = number.group(0) if number else None
    try:
        index = int(str(candidate).strip()) - 1
    except ValueError:
        return None
    return index if 0 <= index < count else None


async def select_template(
    cfg: LlmConfig, templates: list[SummaryTemplate], content: str, custom_prompt: str
) -> SummaryTemplate:
    """Let the LLM pick a template; falls back to ``templates[0]`` (the admin's default)."""
    if not templates:
        raise SummaryError("No summary template is enabled")
    if len(templates) == 1:
        return templates[0]
    try:
        completion = await chat_completion(
            cfg, TEMPLATE_SELECTION_SYSTEM_PROMPT, build_template_selection_user_prompt(templates, content, custom_prompt)
        )
    except LlmError as exc:
        logger.warning("Template selection failed, using default template '%s': %s", templates[0].id, exc)
        return templates[0]
    index = parse_template_selection(completion.content, len(templates))
    if index is None:
        logger.warning("Unusable template selection reply %r; using default '%s'", completion.content[:200], templates[0].id)
        return templates[0]
    return templates[index]


@dataclass
class GeneratedSummary:
    final_markdown: str
    template: SummaryTemplate
    successful_chunk_count: int
    reasoning_stripped: bool


async def _complete(cfg: LlmConfig, system: str, user: str, output_format: str | None = None) -> CleanedMarkdown:
    completion = await chat_completion(cfg, system, user)
    cleaned = clean_llm_markdown(completion.content)
    cleaned.reasoning_stripped |= completion.reasoning_stripped
    if output_format == FORMAT_HTML:
        cleaned.markdown = normalize_html_document(cleaned.markdown)
    return cleaned


async def generate_meeting_summary(
    cfg: LlmConfig,
    text: str,
    custom_prompt: str,
    templates: list[SummaryTemplate],
    token_threshold: int,
) -> GeneratedSummary:
    """Map-reduce summary with automatic template selection.

    ``templates`` are the enabled templates, default first. The chosen template's prompt is sent verbatim as the system
    prompt of the final report: the server adds no rules of its own (language, format, title, ...). Cancellation is via
    task cancellation (asyncio.CancelledError).
    """
    reasoning_stripped = False
    content = text
    chunk_count = 1
    if rough_token_count(text) >= token_threshold:
        chunks = chunk_text(text, max(token_threshold - 300, 200), 100)
        logger.info("Transcript exceeds %d tokens; summarizing %d chunks", token_threshold, len(chunks))
        summaries: list[str] = []
        for index, chunk in enumerate(chunks):
            prompt = build_chunk_summary_user_prompt(chunk)
            for attempt in range(1, MAX_CHUNK_ATTEMPTS + 1):
                try:
                    cleaned = await _complete(cfg, "You are an expert meeting summarizer.", prompt)
                    require_visible_markdown("Summary chunk", cleaned)
                    reasoning_stripped |= cleaned.reasoning_stripped
                    summaries.append(cleaned.markdown)
                    break
                except (LlmError, SummaryError) as exc:
                    if attempt < MAX_CHUNK_ATTEMPTS:
                        logger.warning("Chunk %d/%d attempt %d failed: %s; retrying", index + 1, len(chunks), attempt, exc)
                        continue
                    raise SummaryError(
                        f"Summary generation could not complete because transcript section {index + 1} of "
                        f"{len(chunks)} failed after {MAX_CHUNK_ATTEMPTS} attempts: {exc}. Please retry."
                    ) from exc
        chunk_count = len(summaries)
        if len(summaries) == 1:
            content = summaries[0]
        else:
            cleaned = await _complete(
                cfg, "You are an expert at synthesizing meeting summaries.",
                build_combine_summary_user_prompt("\n---\n".join(summaries)),
            )
            require_visible_markdown("Combined summary", cleaned)
            reasoning_stripped |= cleaned.reasoning_stripped
            content = cleaned.markdown

    template = await select_template(cfg, templates, content, custom_prompt)
    logger.info("Generating final %s report with template: %s", template.output_format, template.id)
    user = f"<transcript_chunks>\n{content}\n</transcript_chunks>\n"
    if custom_prompt:
        user += f"\n\nUser Provided Context:\n\n<user_context>\n{custom_prompt}\n</user_context>"
    cleaned = await _complete(cfg, template.prompt.strip(), user, template.output_format)
    require_visible_markdown("Final summary", cleaned)
    reasoning_stripped |= cleaned.reasoning_stripped

    return GeneratedSummary(
        final_markdown=cleaned.markdown,
        template=template,
        successful_chunk_count=chunk_count,
        reasoning_stripped=reasoning_stripped,
    )
