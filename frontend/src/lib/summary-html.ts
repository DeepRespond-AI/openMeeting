import DOMPurify from 'dompurify';
import { marked } from 'marked';
import type { SummaryOutputFormat } from '@/types';

/** Formats rendered as (sanitized) HTML instead of being parsed into the BlockNote editor. */
export function isRichSummaryFormat(format: unknown): format is Exclude<SummaryOutputFormat, 'markdown'> {
  return format === 'html' || format === 'mixed';
}

// LLM output is untrusted: no scripts, frames, forms or embedded objects. `<style>` is kept because the
// result is mounted in a shadow root, which scopes it to the summary.
const FORBID_TAGS = ['form', 'input', 'button', 'select', 'textarea', 'iframe', 'frame', 'object', 'embed', 'base', 'link', 'meta'];

/**
 * Sanitized HTML for a server summary body (server/API.md §1.6):
 * `html` is used as-is, `markdown` / `mixed` (Markdown with raw HTML) go through marked first.
 */
export function renderSummaryHtml(content: string, format: SummaryOutputFormat): string {
  const html = format === 'html' ? content : (marked.parse(content, { gfm: true, async: false }) as string);
  return DOMPurify.sanitize(html, { FORBID_TAGS });
}
