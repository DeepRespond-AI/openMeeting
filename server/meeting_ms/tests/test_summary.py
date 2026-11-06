from __future__ import annotations

import asyncio
import json
import re
import uuid

import httpx
import pytest
import respx

from sqlalchemy import delete

from meeting_ms.db.models import SummaryTemplateRow
from meeting_ms.db.session import session_factory
from meeting_ms.summary.processor import (
    SummaryError,
    chunk_text,
    clean_llm_markdown,
    extract_meeting_name,
    normalize_html_document,
    parse_template_selection,
    require_visible_markdown,
)
from meeting_ms.summary.service import strip_title_if_present
from meeting_ms.summary.templates import seed_rows
from meeting_ms.tests.conftest import user_headers

LLM_BASE = "http://llm.test/v1"

FINAL_MD = "<think>private reasoning</think>\n# Weekly Sync\n\n**Summary**\n\nThe team agreed on the Q4 budget."
FINAL_HTML = (
    "```html\n<!DOCTYPE html><html><head><title>x</title><style>p{margin:0}</style></head><body>"
    "<h1>Budget &amp; Plan</h1>\n<h2>Summary</h2><p style=\"color:#1F55F0\">Q4 budget agreed.</p></body></html>\n```"
)
FINAL_MIXED = "# Mixed Sync\n\n## Summary\n\nBudget <mark>agreed</mark>.\n\n<details><summary>More</summary>\n\nDetails.\n\n</details>"
SELECTION_PREFIX = "You choose the report template"
HTML_PROMPT = "Write an HTML report with a colored summary paragraph."
MIXED_PROMPT = "Write a mixed report."


def _reply(content: str) -> httpx.Response:
    return httpx.Response(200, json={"choices": [{"message": {"role": "assistant", "content": content}}]})


class FakeLlm:
    def __init__(self, delay: float = 0.0, pick: str | None = "Standard Meeting Notes") -> None:
        self.calls: list[dict] = []
        self.delay = delay
        # Template name the fake selector answers with (None → an unusable reply).
        self.pick = pick

    async def __call__(self, request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content)
        self.calls.append(body)
        if self.delay:
            await asyncio.sleep(self.delay)
        system = body["messages"][0]["content"]
        user = body["messages"][1]["content"]
        if "connectivity test" in system:
            return _reply("OK")
        if system.startswith(SELECTION_PREFIX):
            if self.pick is None:
                return _reply("I cannot decide.")
            number = re.search(rf"^(\d+)\. {re.escape(self.pick)}$", user, re.MULTILINE).group(1)
            return _reply(f'{{"template": {number}}}')
        if system == "You are an expert meeting summarizer.":
            return _reply("- chunk summary")
        if system.startswith("You are an expert at synthesizing"):
            return _reply("Combined narrative.")
        # Final report: the system prompt is the template prompt itself.
        if "HTML report" in system:
            return _reply(FINAL_HTML)
        if system == MIXED_PROMPT:
            return _reply(FINAL_MIXED)
        return _reply(FINAL_MD)


def _final_call(calls: list[dict]) -> dict:
    return next(c for c in calls if c["messages"][1]["content"].startswith("<transcript_chunks>"))


async def _setup(client: httpx.AsyncClient, admin: httpx.AsyncClient, context_tokens: int = 32000):
    r = await admin.post(
        "/admin/api/llm/providers",
        json={"name": "百炼", "base_url": LLM_BASE, "model": "qwen-plus", "api_key": "sk-test",
              "context_tokens": context_tokens, "temperature": 0.2},
    )
    assert r.status_code == 200, r.text
    provider = r.json()
    assert provider["active"] is True and provider["api_key_set"] is True and "api_key" not in provider
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "Untitled"}, headers=h)).json()["id"]
    segs = [
        {"id": str(uuid.uuid4()), "text": f"We discussed the budget for quarter four, item {i}.", "timestamp": "t",
         "audio_start_time": float(i * 3), "audio_end_time": float(i * 3 + 2)}
        for i in range(5)
    ]
    await client.post(f"/api/v1/meetings/{mid}/transcripts", json={"transcripts": segs}, headers=h)
    return provider, h, mid


async def _wait_summary(client: httpx.AsyncClient, mid: str, h: dict) -> dict:
    for _ in range(200):
        s = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
        if s["status"] not in ("pending", "processing"):
            return s
        await asyncio.sleep(0.05)
    raise AssertionError("summary did not finish")


async def test_summary_requires_llm(client: httpx.AsyncClient) -> None:
    h = user_headers()
    mid = (await client.post("/api/v1/meetings", json={"title": "x"}, headers=h)).json()["id"]
    idle = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
    assert idle == {"status": "idle", "meetingName": "x", "meeting_id": mid, "start": None, "end": None,
                    "data": None, "error": None}
    r = await client.post(f"/api/v1/meetings/{mid}/summary", json={"text": "hello"}, headers=h)
    assert r.status_code == 503


@respx.mock(assert_all_called=False)
async def test_summary_pipeline(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    llm = FakeLlm()
    respx_mock.post(f"{LLM_BASE}/chat/completions").mock(side_effect=llm)
    provider, h, mid = await _setup(client, admin)

    test = (await admin.post(f"/admin/api/llm/providers/{provider['id']}/test")).json()
    assert test["ok"] is True and test["reply"] == "OK"
    assert llm.calls[-1]["temperature"] == 0.2

    # A client-sent template_id is ignored: the server picks the template.
    r = await client.post(f"/api/v1/meetings/{mid}/summary", json={"template_id": "daily_standup", "language": "en"}, headers=h)
    assert r.status_code == 202, r.text
    process_id = r.json()["process_id"]
    assert process_id.endswith("Z") and len(process_id.split(".")[1]) == 10  # 9 fractional digits + Z

    s = await _wait_summary(client, mid, h)
    assert s["status"] == "completed", s
    assert s["start"] == process_id and s["end"]
    assert s["meetingName"] == "Weekly Sync"
    data = s["data"]
    assert data["markdown"].startswith("**Summary**") and data["format"] == "markdown"
    assert "private reasoning" not in json.dumps(data)
    assert data["reasoning_stripped"] is True and "normalization_fallback" not in data
    # The chosen template is server-side only.
    assert "template" not in data

    selection = next(c for c in llm.calls if c["messages"][0]["content"].startswith(SELECTION_PREFIX))
    assert "Daily Standup" in selection["messages"][1]["content"]
    assert "[00:03] We discussed the budget" in selection["messages"][1]["content"]
    # The template prompt is the whole system prompt: the server adds no rules of its own.
    templates = {t["id"]: t for t in (await admin.get("/admin/api/summary-templates")).json()}
    final_call = _final_call(llm.calls)
    assert final_call["messages"][0]["content"] == templates["standard_meeting"]["prompt"]
    user_prompt = final_call["messages"][1]["content"]
    assert "[00:03] We discussed the budget" in user_prompt
    assert final_call["model"] == "qwen-plus"

    # A client-sent language is ignored too: regenerating is selection + final report, with no translation pass.
    before = len(llm.calls)
    await client.post(f"/api/v1/meetings/{mid}/summary", json={"template_id": "standard_meeting", "language": "zh"}, headers=h)
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "completed" and s["data"]["markdown"].startswith("**Summary**")
    new_calls = llm.calls[before:]
    assert len(new_calls) == 2 and new_calls[0]["messages"][0]["content"].startswith(SELECTION_PREFIX)
    assert new_calls[1]["messages"][0]["content"] == templates["standard_meeting"]["prompt"]

    # Manual edit.
    edited = {"markdown": "Edited summary", "summary_json": [{"content": [{"type": "text", "text": "Edited"}]}]}
    assert (await client.put(f"/api/v1/meetings/{mid}/summary", json={"summary": edited}, headers=h)).status_code == 204
    s = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
    assert s["data"]["markdown"] == "Edited summary" and s["data"]["format"] == "markdown"
    bad = {"markdown": "<think>oops"}
    assert (await client.put(f"/api/v1/meetings/{mid}/summary", json={"summary": bad}, headers=h)).status_code == 400

    detail = (await admin.get(f"/admin/api/meetings/{mid}")).json()
    # user_name 来自 user_ms 的批量查询；本测试进程内 user_ms 不存在 → 降级 None。
    # 该跨域 join 已移至 user_ms 域，真实链路由网关联调（e2e）验证。
    assert detail["user_name"] is None and detail["summary"]["status"] == "completed"
    assert detail["summary"]["data"]["template"] == {"id": "standard_meeting", "name": "Standard Meeting Notes"}
    listing = (await admin.get("/admin/api/meetings")).json()
    assert listing["total"] == 1 and listing["items"][0]["has_summary"] is True
    jobs = (await admin.get("/admin/api/jobs?status=completed")).json()
    assert {j["kind"] for j in jobs} == {"summary"}


@respx.mock(assert_all_called=False)
async def test_summary_chunking(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    llm = FakeLlm()
    respx_mock.post(f"{LLM_BASE}/chat/completions").mock(side_effect=llm)
    _, h, mid = await _setup(client, admin, context_tokens=1000)
    long_text = " ".join(f"Sentence number {i} about the roadmap." for i in range(800))
    await client.post(f"/api/v1/meetings/{mid}/summary", json={"text": long_text, "language": "en"}, headers=h)
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "completed", s
    chunk_calls = [c for c in llm.calls if c["messages"][0]["content"] == "You are an expert meeting summarizer."]
    combine_calls = [c for c in llm.calls if c["messages"][0]["content"].startswith("You are an expert at synthesizing")]
    assert len(chunk_calls) > 1 and len(combine_calls) == 1
    assert "English" not in chunk_calls[0]["messages"][1]["content"]
    final_call = _final_call(llm.calls)
    assert "Combined narrative." in final_call["messages"][1]["content"]


@respx.mock(assert_all_called=False)
async def test_summary_cancel_and_failure(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    route = respx_mock.post(f"{LLM_BASE}/chat/completions")
    route.mock(side_effect=FakeLlm(delay=5))
    _, h, mid = await _setup(client, admin)
    await client.post(f"/api/v1/meetings/{mid}/summary", json={}, headers=h)
    s = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
    assert s["status"] == "pending"
    assert (await client.delete(f"/api/v1/meetings/{mid}/summary", headers=h)).status_code == 204
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "cancelled" and s["error"] == "Generation was cancelled by user"

    route.mock(return_value=httpx.Response(500, text="upstream down"))
    await client.post(f"/api/v1/meetings/{mid}/summary", json={}, headers=h)
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "failed" and "500" in s["error"]


@respx.mock(assert_all_called=False)
async def test_summary_html_template(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    llm = FakeLlm(pick="HTML 纪要")
    respx_mock.post(f"{LLM_BASE}/chat/completions").mock(side_effect=llm)
    _, h, mid = await _setup(client, admin)
    r = await admin.post("/admin/api/summary-templates", json={
        "name": "HTML 纪要", "description": "预算会议", "prompt": HTML_PROMPT, "output_format": "html",
    })
    assert r.status_code == 200, r.text
    tpl = r.json()

    await client.post(f"/api/v1/meetings/{mid}/summary", json={"language": "en"}, headers=h)
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "completed", s
    assert s["meetingName"] == "Budget & Plan"
    assert s["data"]["format"] == "html"
    # A full document is reduced to its body; the <style> from <head> is kept and the leading <h1> becomes the title.
    assert s["data"]["markdown"] == '<style>p{margin:0}</style>\n<h2>Summary</h2><p style="color:#1F55F0">Q4 budget agreed.</p>'
    assert _final_call(llm.calls)["messages"][0]["content"] == HTML_PROMPT

    # An edited template prompt is used verbatim on the next generation.
    await admin.put(f"/admin/api/summary-templates/{tpl['id']}", json={**{k: tpl[k] for k in (
        "name", "description", "output_format")}, "prompt": "Changed HTML report prompt."})
    before = len(llm.calls)
    await client.post(f"/api/v1/meetings/{mid}/summary", json={}, headers=h)
    await _wait_summary(client, mid, h)
    assert _final_call(llm.calls[before:])["messages"][0]["content"] == "Changed HTML report prompt."

    # Manual edits keep the stored format; unknown formats are rejected.
    body = {"summary": {"markdown": "<p>edited</p>"}}
    assert (await client.put(f"/api/v1/meetings/{mid}/summary", json=body, headers=h)).status_code == 204
    s = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
    assert s["data"] == {"markdown": "<p>edited</p>", "format": "html"}
    detail = (await admin.get(f"/admin/api/meetings/{mid}")).json()
    assert detail["summary"]["data"]["template"]["id"] == tpl["id"]
    # BlockNote edits (desktop) are Markdown even when an older client omits `format`.
    blocknote = {"summary": {"markdown": "Edited", "summary_json": [{"content": [{"type": "text", "text": "Edited"}]}]}}
    assert (await client.put(f"/api/v1/meetings/{mid}/summary", json=blocknote, headers=h)).status_code == 204
    s = (await client.get(f"/api/v1/meetings/{mid}/summary", headers=h)).json()
    assert s["data"]["format"] == "markdown"
    bad = {"summary": {"markdown": "x", "format": "pdf"}}
    assert (await client.put(f"/api/v1/meetings/{mid}/summary", json=bad, headers=h)).status_code == 400


@respx.mock(assert_all_called=False)
async def test_summary_mixed_and_selection_fallback(respx_mock, client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    llm = FakeLlm(pick=None)
    respx_mock.post(f"{LLM_BASE}/chat/completions").mock(side_effect=llm)
    _, h, mid = await _setup(client, admin)
    r = await admin.post("/admin/api/summary-templates", json={
        "name": "混合", "description": "任意会议", "prompt": MIXED_PROMPT, "output_format": "mixed",
        "is_default": True,
    })
    assert r.json()["is_default"] is True
    templates = (await admin.get("/admin/api/summary-templates")).json()
    assert [t["id"] for t in templates if t["is_default"]] == [r.json()["id"]]

    # Unusable selector reply → the admin's default template.
    await client.post(f"/api/v1/meetings/{mid}/summary", json={"language": "en"}, headers=h)
    s = await _wait_summary(client, mid, h)
    assert s["status"] == "completed", s
    assert s["meetingName"] == "Mixed Sync" and s["data"]["format"] == "mixed"
    assert s["data"]["markdown"].startswith("## Summary") and "<mark>agreed</mark>" in s["data"]["markdown"]


async def test_summary_requires_template(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    _, h, mid = await _setup(client, admin)
    async with session_factory()() as session:
        await session.execute(delete(SummaryTemplateRow))
        await session.commit()
    r = await client.post(f"/api/v1/meetings/{mid}/summary", json={}, headers=h)
    assert r.status_code == 503


async def test_template_admin(client: httpx.AsyncClient, admin: httpx.AsyncClient) -> None:
    listing = (await admin.get("/admin/api/summary-templates")).json()
    by_id = {t["id"]: t for t in listing}
    assert {"daily_standup", "standard_meeting"} <= set(by_id)
    std = by_id["standard_meeting"]
    assert std["is_default"] is True and std["output_format"] == "markdown" and std["enabled"] is True
    assert "## Action Items" in std["prompt"] and "| **Owner** |" in std["prompt"]

    base = {"name": "T", "description": "d", "prompt": "p"}
    assert (await admin.post("/admin/api/summary-templates", json={**base, "output_format": "pdf"})).status_code == 422
    assert (await admin.post("/admin/api/summary-templates", json={**base, "prompt": "  "})).status_code == 422
    assert (await admin.put("/admin/api/summary-templates/nope", json=base)).status_code == 404

    # At least one template must stay enabled.
    for t in listing[:-1]:
        r = await admin.put(f"/admin/api/summary-templates/{t['id']}", json={**base, "enabled": False})
        assert r.status_code == 200 and r.json()["is_default"] is False
    last = listing[-1]
    assert (await admin.put(f"/admin/api/summary-templates/{last['id']}", json={**base, "enabled": False})).status_code == 400
    assert (await admin.delete(f"/admin/api/summary-templates/{last['id']}")).status_code == 400
    assert (await admin.delete(f"/admin/api/summary-templates/{listing[0]['id']}")).status_code == 204
    assert len((await admin.get("/admin/api/summary-templates")).json()) == len(listing) - 1

    # Clients no longer see templates at all.
    h = user_headers()
    assert (await client.get("/api/v1/templates", headers=h)).status_code == 404
    # 管理端 JWT 校验已上移网关（本服务的 /admin/api/* 不再做本地鉴权，见 gateway_ms/tests）。


def test_template_seed() -> None:
    rows = {r["id"]: r for r in seed_rows()}
    assert len(rows) == 6 and [i for i, r in rows.items() if r["is_default"]] == ["standard_meeting"]
    assert all(r["output_format"] == "markdown" and r["prompt"] for r in rows.values())
    # Format and title requirements live in the template prompt itself, where admins can edit them.
    assert all(r["prompt"].startswith("Write the report in GitHub-flavored Markdown.") for r in rows.values())


def test_template_selection_parsing() -> None:
    assert parse_template_selection('{"template": 2}', 3) == 1
    assert parse_template_selection('<think>hmm 1</think>```json\n{"template": "3"}\n```', 3) == 2
    assert parse_template_selection("Template 2 fits best", 3) == 1
    assert parse_template_selection('{"template": 9}', 3) is None
    assert parse_template_selection("no idea", 3) is None


def test_format_helpers() -> None:
    assert normalize_html_document("<html><body><h1>T</h1></body></html>") == "<h1>T</h1>"
    assert normalize_html_document("<!DOCTYPE html><h1>T</h1>") == "<h1>T</h1>"
    assert normalize_html_document(
        "<html><head><title>x</title><style>h1{color:red}</style></head><body><h1>T</h1></body></html>"
    ) == "<style>h1{color:red}</style>\n<h1>T</h1>"
    assert extract_meeting_name('<h1 class="t">A <b>&amp;</b> B</h1><p>x</p>', "html") == "A & B"
    assert extract_meeting_name("# Title\n\nbody", "mixed") == "Title"
    assert extract_meeting_name("<h1>Title</h1>\n\nbody", "mixed") == "Title"
    assert extract_meeting_name("<style>p{}</style>\n<h1>T</h1>", "html") == "T"
    # Only a leading heading names the meeting.
    assert extract_meeting_name("## Intro\n\n# Later", "markdown") is None
    assert extract_meeting_name("<p>x</p><h1>Later</h1>", "html") is None
    assert strip_title_if_present("<h1>T</h1>\n<p>x</p>") == "<p>x</p>"
    assert strip_title_if_present("# T\n\nbody") == "body"
    assert strip_title_if_present("<p>no title</p>") == "<p>no title</p>"
    assert strip_title_if_present("<style>p{}</style>\n<h1>T</h1>\n<p>x</p>") == "<style>p{}</style>\n<p>x</p>"
    assert clean_llm_markdown("```html\n<p>x</p>\n```").markdown == "<p>x</p>"


def test_chunk_text_port() -> None:
    assert chunk_text("é ab", 1, 0) == ["é ", "ab"]
    assert chunk_text("abcd", 1, 1) == ["abc", "bcd"]
    text = "Intro. LOST_MARKER trailing content ensures chunking"
    assert any("LOST_MARKER" in c for c in chunk_text(text, 10, 1))


def test_clean_markdown_port() -> None:
    cleaned = clean_llm_markdown("```\n<think>private</think>\nvisible\n```")
    assert cleaned.markdown == "visible" and cleaned.reasoning_stripped
    assert clean_llm_markdown("<thinker>Visible</thinker>").markdown == "<thinker>Visible</thinker>"
    with pytest.raises(SummaryError, match="unterminated"):
        require_visible_markdown("Final summary", clean_llm_markdown("Visible\n<think>private"))
    with pytest.raises(SummaryError, match="no visible"):
        require_visible_markdown("Translation", clean_llm_markdown("```markdown\n```"))
