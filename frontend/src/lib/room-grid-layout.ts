/** V2's 320px tile baseline, bounded by the actual stage rather than the window. */
export function roomGridLayout(width: number, height: number, participants: number) {
  const count = Math.max(0, Math.floor(participants));
  const gap = 12;
  const columns = Math.max(1, Math.min(Math.max(count, 1), Math.floor((Math.max(0, width) + gap) / (320 + gap))));
  const remainder = count % columns;
  const inviteSpan = count === 0 ? 1 : remainder === 0 ? 0 : columns - remainder;
  const rows = Math.max(1, Math.ceil((count || 1) / columns));
  // Short windows and large rooms scroll the stage instead of crushing tiles.
  const minHeight = 136;
  return { columns, rows, inviteSpan, minHeight, scroll: rows * minHeight + (rows - 1) * gap > height };
}
