"use client";

import { useEffect, useRef } from 'react';
import type { SummaryOutputFormat } from '@/types';
import { renderSummaryHtml } from '@/lib/summary-html';

// Base typography inside the shadow root. Inherited CSS custom properties (theme tokens from globals.css)
// cross the shadow boundary; app stylesheets (Tailwind) do not, and the summary's own styles do not leak out.
const BASE_CSS = `
:host { display: block; color: hsl(var(--foreground)); font-size: 0.9375rem; line-height: 1.7; word-break: break-word; }
h1, h2, h3, h4 { color: hsl(var(--foreground)); font-weight: 600; line-height: 1.35; margin: 1.25em 0 0.5em; }
h1 { font-size: 1.5rem; } h2 { font-size: 1.25rem; } h3 { font-size: 1.0625rem; } h4 { font-size: 1rem; }
:first-child { margin-top: 0; }
p { margin: 0.5em 0; }
ul, ol { margin: 0.5em 0; padding-left: 1.5em; }
li { margin: 0.25em 0; }
a { color: hsl(var(--primary)); text-decoration: underline; cursor: default; }
strong { font-weight: 600; }
hr { border: 0; border-top: 1px solid hsl(var(--border)); margin: 1.25em 0; }
blockquote { margin: 0.75em 0; padding: 0.25em 1em; border-left: 3px solid hsl(var(--primary)); background: hsl(var(--accent)); color: hsl(var(--secondary-foreground)); border-radius: 0 calc(var(--radius) - 4px) calc(var(--radius) - 4px) 0; }
code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.875em; background: hsl(var(--muted)); padding: 0.1em 0.35em; border-radius: 4px; }
pre { background: hsl(var(--muted)); padding: 0.75em 1em; border-radius: calc(var(--radius) - 4px); overflow-x: auto; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; margin: 0.75em 0; display: block; overflow-x: auto; max-width: 100%; }
th, td { border: 1px solid hsl(var(--border)); padding: 0.4em 0.75em; text-align: left; vertical-align: top; }
th { background: hsl(var(--muted)); font-weight: 600; }
mark { background: hsl(var(--warning) / 0.25); color: inherit; padding: 0 0.15em; border-radius: 3px; }
details { margin: 0.5em 0; } summary { cursor: pointer; font-weight: 500; }
img { max-width: 100%; }
`;

interface RichSummaryViewProps {
  /** Summary body from the server (`data.markdown`). */
  content: string;
  format: Exclude<SummaryOutputFormat, 'markdown'>;
}

/**
 * Read-only rendering of HTML / mixed (Markdown + HTML) summaries. The sanitized HTML is mounted in a
 * shadow root so model-provided styles cannot affect the app and app styles do not distort the summary.
 */
export function RichSummaryView({ content, format }: RichSummaryViewProps) {
  const hostRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;
    const root = host.shadowRoot ?? host.attachShadow({ mode: 'open' });
    root.innerHTML = `<style>${BASE_CSS}</style>${renderSummaryHtml(content, format)}`;
  }, [content, format]);

  useEffect(() => {
    const host = hostRef.current;
    const root = host?.shadowRoot;
    if (!root) return;
    // Links must never navigate the app webview away.
    const onClick = (event: Event) => {
      const target = event.target as Element | null;
      if (target?.closest('a')) event.preventDefault();
    };
    root.addEventListener('click', onClick);
    return () => root.removeEventListener('click', onClick);
  }, []);

  return <div ref={hostRef} className="w-full px-1 py-2" />;
}
