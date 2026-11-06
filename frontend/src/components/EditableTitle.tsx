'use client';

import { useRef, useEffect } from 'react';
import { Pencil, Trash2 } from 'lucide-react';
import { useT } from '@/i18n';
import { MEETING_TITLE_MAX, limitText, textLength } from '@/lib/field-limits';

interface EditableTitleProps {
  title: string;
  isEditing: boolean;
  onStartEditing: () => void;
  onFinishEditing: () => void;
  onChange: (value: string) => void;
  onDelete?: () => void;
}

export const EditableTitle: React.FC<EditableTitleProps> = ({
  title,
  isEditing,
  onStartEditing,
  onFinishEditing,
  onChange,
  onDelete,
}) => {
  const t = useT();
  const titleInputRef = useRef<HTMLTextAreaElement>(null);

  // Auto-resize textarea height based on content
  useEffect(() => {
    if (titleInputRef.current && isEditing) {
      titleInputRef.current.style.height = 'auto';
      titleInputRef.current.style.height = `${titleInputRef.current.scrollHeight}px`;
    }
  }, [title, isEditing]);

  return isEditing ? (
    <div className="flex-1">
      <textarea
        ref={titleInputRef}
        value={title}
        maxLength={MEETING_TITLE_MAX * 2}
        onChange={(e) => onChange((e.nativeEvent as InputEvent).isComposing ? e.target.value : limitText(e.target.value, MEETING_TITLE_MAX))}
        onCompositionEnd={(e) => onChange(limitText(e.currentTarget.value, MEETING_TITLE_MAX))}
        onBlur={onFinishEditing}
        onKeyDown={(e) => {
          if (e.nativeEvent.isComposing || e.keyCode === 229) return;
          // Allow Enter for new line only with Shift key
          if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            onFinishEditing();
          }
        }}
        className="w-full resize-none overflow-hidden rounded-lg border border-input bg-card px-3 py-1 text-xl font-semibold text-foreground focus:outline-none focus:ring-2 focus:ring-ring/40"
        style={{ minWidth: '240px', minHeight: '40px' }}
        autoFocus
        rows={1}
      />
      <div role="status" className="text-right text-xs tabular-nums text-muted-foreground">{textLength(title)}/{MEETING_TITLE_MAX}</div>
    </div>
  ) : (
    <div className="group flex flex-1 items-center gap-2">
      <h1
        className="flex-1 cursor-pointer whitespace-pre-wrap rounded-lg px-1 text-xl font-semibold text-foreground transition-colors hover:bg-muted"
        onClick={onStartEditing}
      >
        {title}
      </h1>
      <div className="flex gap-1">
        <button
          type="button"
          onClick={onStartEditing}
          className="rounded-md p-1 text-muted-foreground opacity-0 transition-opacity duration-200 hover:bg-muted hover:text-foreground group-hover:opacity-100"
          title={t('home.editableTitle.edit')}
          aria-label={t('home.editableTitle.edit')}
        >
          <Pencil className="h-4 w-4" />
        </button>
        {onDelete && (
          <button
            type="button"
            onClick={onDelete}
            className="rounded-md p-1 text-destructive opacity-0 transition-opacity duration-200 hover:bg-destructive/10 group-hover:opacity-100"
            title={t('home.editableTitle.delete')}
            aria-label={t('home.editableTitle.delete')}
          >
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  );
};
