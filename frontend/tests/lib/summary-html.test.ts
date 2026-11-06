import { describe, expect, test } from "bun:test";
import { JSDOM } from "jsdom";

// DOMPurify needs a DOM; install one before the module under test is imported.
const { window } = new JSDOM("");
Object.assign(globalThis, { window, document: window.document });
const { isRichSummaryFormat, renderSummaryHtml } = await import("../../src/lib/summary-html");

describe("summary HTML rendering", () => {
  test("only html and mixed are rendered as rich HTML", () => {
    expect(isRichSummaryFormat("html")).toBe(true);
    expect(isRichSummaryFormat("mixed")).toBe(true);
    expect(isRichSummaryFormat("markdown")).toBe(false);
    expect(isRichSummaryFormat(undefined)).toBe(false);
  });

  test("html is sanitized but keeps inline styles", () => {
    const html = renderSummaryHtml(
      '<h2 style="color:red">Summary</h2><script>alert(1)</script><p onclick="x()">ok</p><iframe src="x"></iframe>',
      "html",
    );
    expect(html).toContain('<h2 style="color:red">Summary</h2>');
    expect(html).toContain("<p>ok</p>");
    expect(html).not.toContain("script");
    expect(html).not.toContain("onclick");
    expect(html).not.toContain("iframe");
  });

  test("mixed renders Markdown and keeps embedded HTML", () => {
    const html = renderSummaryHtml("## Summary\n\nBudget <mark>agreed</mark>.\n\n| a | b |\n| - | - |\n| 1 | 2 |", "mixed");
    expect(html).toContain("<h2>Summary</h2>");
    expect(html).toContain("<mark>agreed</mark>");
    expect(html).toContain("<table>");
  });

  test("markdown is not treated as HTML", () => {
    expect(renderSummaryHtml("**bold**", "markdown")).toContain("<strong>bold</strong>");
    expect(renderSummaryHtml("**bold**", "html")).toBe("**bold**");
  });
});
