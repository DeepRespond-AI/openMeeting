import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/context_extensions.dart';

/// Live input level as a row of rounded bars (newest on the right).
class LevelWaveform extends StatelessWidget {
  const LevelWaveform({super.key, required this.levels, required this.active});

  /// 0..1, oldest first.
  final List<double> levels;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: context.sizes.touchTarget,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(
          levels: levels,
          color: active ? colors.primary : colors.border,
          minBar: context.sizes.borderWidth * 2,
          gap: context.spacing.xxs / 2,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
    required this.minBar,
    required this.gap,
  });

  final List<double> levels;
  final Color color;
  final double minBar;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final slot = size.width / levels.length;
    final barWidth = math.max(minBar, slot - gap);
    final paint = Paint()..color = color;
    final radius = Radius.circular(barWidth / 2);
    for (var i = 0; i < levels.length; i++) {
      final h = math.max(minBar, levels[i] * size.height);
      final left = i * slot + (slot - barWidth) / 2;
      final top = (size.height - h) / 2;
      canvas.drawRRect(RRect.fromLTRBR(left, top, left + barWidth, top + h, radius), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.levels != levels || old.color != color;
}
