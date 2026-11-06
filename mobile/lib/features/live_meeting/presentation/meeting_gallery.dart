import 'package:flutter/material.dart';

import '../../../core/theme/context_extensions.dart';
import '../domain/room_grid_layout.dart';

/// Stable child identities keep camera renderers mounted when rows/columns change.
class MeetingGallery extends StatelessWidget {
  const MeetingGallery({required this.tiles, required this.invite, super.key});
  final Map<String, Widget> tiles;
  final Widget invite;

  @override
  Widget build(BuildContext context) => Padding(
    padding: context.spacing.page,
    child: LayoutBuilder(
      builder: (context, box) {
        final gap = context.spacing.sm;
        final layout = RoomGridLayout.fit(
          width: box.maxWidth,
          height: box.maxHeight,
          count: tiles.length,
          gap: gap,
          minExtent: context.sizes.touchTarget * 3,
        );
        return SingleChildScrollView(
          key: const ValueKey('meeting-gallery-scroll'),
          child: SizedBox(
            width: box.maxWidth,
            height: layout.height,
            child: CustomMultiChildLayout(
              key: const ValueKey('meeting-gallery-stage'),
              delegate: _GalleryLayout(layout, tiles.keys.toList(), gap),
              children: [
                for (final entry in tiles.entries)
                  LayoutId(key: ValueKey(entry.key), id: entry.key, child: entry.value),
                if (layout.inviteSpan > 0) LayoutId(id: #invite, child: invite),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _GalleryLayout extends MultiChildLayoutDelegate {
  _GalleryLayout(this.layout, this.ids, this.gap);
  final RoomGridLayout layout;
  final List<String> ids;
  final double gap;
  @override
  void performLayout(Size size) {
    final width = (size.width - gap * (layout.columns - 1)) / layout.columns;
    final height = (size.height - gap * (layout.rows - 1)) / layout.rows;
    void place(Object id, int index, int span) {
      layoutChild(id, BoxConstraints.tight(Size(width * span + gap * (span - 1), height)));
      positionChild(
        id,
        Offset(
          (index % layout.columns) * (width + gap),
          (index ~/ layout.columns) * (height + gap),
        ),
      );
    }

    for (var i = 0; i < ids.length; i++) {
      place(ids[i], i, 1);
    }
    if (layout.inviteSpan > 0) place(#invite, ids.length, layout.inviteSpan);
  }

  @override
  bool shouldRelayout(covariant _GalleryLayout oldDelegate) => true;
}
