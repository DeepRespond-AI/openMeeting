"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { LANGUAGE_OPTIONS } from "@/lib/summary-languages";
import { useRecentLanguages } from "@/hooks/useRecentLanguages";
import { Check, Search } from "lucide-react";
import { useI18n } from "@/i18n";
import { cn } from "@/lib/utils";
import { languageDisplayName } from "@/components/LanguageSelection";

type Option = { code: string; label: string; english: string };

interface LanguagePickerPopoverProps {
  value: string | null;
  onChange: (code: string | null) => void;
  onClose: () => void;
  mode?: "meeting" | "settings";
  autoSubtitle?: string;
}

export function LanguagePickerPopover({
  value,
  onChange,
  onClose,
  mode = "meeting",
  autoSubtitle,
}: LanguagePickerPopoverProps) {
  const { t, locale } = useI18n();
  const { recents } = useRecentLanguages();
  const [query, setQuery] = useState("");
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (!containerRef.current?.contains(e.target as Node)) onClose();
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("mousedown", onDocClick);
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDocClick);
      document.removeEventListener("keydown", onKey);
    };
  }, [onClose]);

  const filter = query.trim().toLowerCase();

  const recentCodes = useMemo(() => new Set(recents), [recents]);

  // Localized labels; search matches the localized name, the English name and the code.
  const localized: Option[] = useMemo(
    () =>
      LANGUAGE_OPTIONS.map((l) => ({
        code: l.code,
        english: l.label,
        label: languageDisplayName(l.code, locale, l.label),
      })),
    [locale],
  );

  const matches = (l: Option) =>
    !filter ||
    l.code.toLowerCase().includes(filter) ||
    l.label.toLowerCase().includes(filter) ||
    l.english.toLowerCase().includes(filter);

  const filteredAll = useMemo(() => {
    const options = mode === "meeting"
      ? localized.filter((l) => !recentCodes.has(l.code))
      : localized;
    return options.filter(matches);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filter, mode, recentCodes, localized]);

  const recentsResolved = useMemo(
    () =>
      recents
        .map((code) => localized.find((l) => l.code === code))
        .filter((l): l is Option => Boolean(l))
        .filter(matches),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [recents, filter, localized],
  );

  const autoLabel = t("recording.picker.auto");
  const showAuto =
    mode === "meeting" &&
    (!filter || "auto".includes(filter) || autoLabel.toLowerCase().includes(filter));
  const showRecents = mode === "meeting" && recentsResolved.length > 0;
  const hasNoResults =
    filteredAll.length === 0 && recentsResolved.length === 0 && !showAuto;

  const itemClass = (selected: boolean) =>
    cn(
      "flex w-full items-center justify-between gap-2 px-3 py-1.5 text-left text-sm transition-colors hover:bg-accent",
      selected ? "font-medium text-primary" : "text-foreground",
    );

  const renderOption = (opt: Option, keyPrefix: string) => (
    <button
      key={`${keyPrefix}-${opt.code}`}
      type="button"
      aria-pressed={value === opt.code}
      onClick={() => onChange(opt.code)}
      className={itemClass(value === opt.code)}
    >
      <span className="min-w-0 truncate">
        {opt.label} <span className="text-xs text-muted-foreground">({opt.code})</span>
      </span>
      {value === opt.code && <Check className="h-4 w-4 shrink-0 text-primary" aria-hidden="true" />}
    </button>
  );

  const sectionLabel = "px-3 pb-1 pt-1 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground";

  return (
    <div
      ref={containerRef}
      className="w-72 overflow-hidden rounded-xl border border-border bg-popover text-popover-foreground shadow-elevated"
      role="dialog"
      aria-label={t("recording.picker.ariaLabel")}
    >
      <div className="flex items-center gap-2 border-b border-border px-3 py-2.5">
        <Search className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden="true" />
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder={t("recording.picker.search")}
          className="min-w-0 flex-1 border-none bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground"
        />
      </div>

      <div className="max-h-80 overflow-y-auto py-1">
        {showRecents && (
          <>
            <div className={sectionLabel}>{t("recording.picker.recent")}</div>
            {recentsResolved.map((opt) => renderOption(opt, "recent"))}
            <div className="my-1 h-px bg-border" />
          </>
        )}

        {showAuto && (
          <button
            type="button"
            aria-pressed={value === null}
            onClick={() => onChange(null)}
            className={itemClass(value === null)}
          >
            <span className="flex min-w-0 flex-col">
              <span>{autoLabel}</span>
              {autoSubtitle && (
                <span className="truncate text-xs font-normal text-muted-foreground">{autoSubtitle}</span>
              )}
            </span>
            {value === null && <Check className="h-4 w-4 shrink-0 text-primary" aria-hidden="true" />}
          </button>
        )}

        {filteredAll.length > 0 && (
          <div className={sectionLabel}>
            {mode === "meeting" ? t("recording.picker.other") : t("recording.picker.all")}
          </div>
        )}

        {filteredAll.map((opt) => renderOption(opt, "all"))}

        {hasNoResults && (
          <div className="px-3 py-2 text-sm text-muted-foreground">{t("recording.picker.noMatches")}</div>
        )}
      </div>
    </div>
  );
}
