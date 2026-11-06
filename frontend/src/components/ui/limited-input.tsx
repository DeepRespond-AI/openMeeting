'use client';

import { forwardRef, useId, type InputHTMLAttributes } from 'react';
import { limitText, textLength } from '@/lib/field-limits';
import { cn } from '@/lib/utils';

type Props = InputHTMLAttributes<HTMLInputElement> & { value: string; maxLength: number };

/** Native safety cap + code-point limit, so emoji count the same as on the API. */
export const LimitedInput = forwardRef<HTMLInputElement, Props>(function LimitedInput(
  { value, maxLength, onChange, onCompositionEnd, onKeyDown, className, 'aria-describedby': describedBy, ...props }, ref,
) {
  const counterId = useId();
  const count = textLength(value);
  return <div className="min-w-0 flex-1">
    <input {...props} ref={ref} value={value}
      // A code point occupies at most two UTF-16 code units in a browser input.
      maxLength={maxLength * 2}
      aria-describedby={[describedBy, counterId].filter(Boolean).join(' ')}
      aria-invalid={count > maxLength || undefined}
      onChange={event => {
        if (!(event.nativeEvent as InputEvent).isComposing) event.target.value = limitText(event.target.value, maxLength);
        onChange?.(event);
      }}
      onCompositionEnd={event => {
        event.currentTarget.value = limitText(event.currentTarget.value, maxLength);
        onChange?.(event as unknown as React.ChangeEvent<HTMLInputElement>);
        onCompositionEnd?.(event);
      }}
      onKeyDown={event => { if (!event.nativeEvent.isComposing && event.keyCode !== 229) onKeyDown?.(event); }}
      className={cn('flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50', className)}
    />
    <div id={counterId} role="status" className={cn('mt-1 text-right text-xs tabular-nums text-muted-foreground', count > maxLength && 'text-destructive')}>
      {count}/{maxLength}
    </div>
  </div>;
});
