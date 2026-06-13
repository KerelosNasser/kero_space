import 'package:flutter/material.dart';
import 'package:kero_space/core/app_theme.dart';

class HeatmapGrid extends StatelessWidget {
  final List<List<int>> matrix; // [row][col] = count
  final void Function(int row, int col) onCellTap;

  const HeatmapGrid({super.key, required this.matrix, required this.onCellTap});

  @override
  Widget build(BuildContext context) {
    final maxVal = matrix.expand((r) => r).fold(1, (a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      final cellW = constraints.maxWidth / (matrix.isEmpty ? 1 : matrix[0].length);
      final cellH = constraints.maxHeight / matrix.length;
      return GestureDetector(
        onTapUp: (d) {
          final col = (d.localPosition.dx / cellW).floor().clamp(0, (matrix[0].length) - 1);
          final row = (d.localPosition.dy / cellH).floor().clamp(0, matrix.length - 1);
          onCellTap(row, col);
        },
        child: CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _HeatmapPainter(matrix: matrix, maxVal: maxVal, cellW: cellW, cellH: cellH),
        ),
      );
    });
  }
}

class _HeatmapPainter extends CustomPainter {
  final List<List<int>> matrix;
  final int maxVal;
  final double cellW;
  final double cellH;

  const _HeatmapPainter(
      {required this.matrix, required this.maxVal, required this.cellW, required this.cellH});

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < matrix.length; r++) {
      for (int c = 0; c < matrix[r].length; c++) {
        final intensity = maxVal > 0 ? matrix[r][c] / maxVal : 0.0;
        final color = Color.lerp(AppTheme.bgElevated, AppTheme.accentCyan, intensity)!;
        final rect = Rect.fromLTWH(c * cellW + 1, r * cellH + 1, cellW - 2, cellH - 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.matrix != matrix || old.maxVal != maxVal;
}
