import 'dart:math' as math;

/// Geometry is based on the available stage, not the device's full screen.
class RoomGridLayout {
  const RoomGridLayout(this.columns, this.rows, this.inviteSpan, this.height);
  final int columns;
  final int rows;
  final int inviteSpan;
  final double height;

  static RoomGridLayout fit({
    required double width,
    required double height,
    required int count,
    required double gap,
    required double minExtent,
  }) {
    final total = math.max(1, count);
    final maxColumns = math.min(total, math.max(1, ((width + gap) / (minExtent + gap)).floor()));
    var best = const RoomGridLayout(1, 1, 0, 0);
    var bestScore = double.infinity;
    for (var columns = 1; columns <= maxColumns; columns++) {
      final rows = (total / columns).ceil();
      final extent = math.max(height, rows * minExtent + (rows - 1) * gap);
      final cellWidth = math.max(1.0, (width - (columns - 1) * gap) / columns);
      final cellHeight = math.max(1.0, (extent - (rows - 1) * gap) / rows);
      final vacant = count == 0 ? 1 : rows * columns - count;
      if (vacant > 1) continue;
      // Prefer square tiles while keeping the last row complete with one
      // invitation of the same size, rather than a large empty invitation area.
      final score = math.log(cellWidth / cellHeight).abs() + vacant / (total * 2);
      if (score < bestScore) {
        bestScore = score;
        best = RoomGridLayout(columns, rows, vacant, extent);
      }
    }
    return best;
  }
}
