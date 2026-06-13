import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/telemetry/presentation/widgets/heatmap_painter.dart';

void main() {
  testWidgets('HeatmapGrid renders without error', (tester) async {
    final matrix = List.generate(1, (_) => List.generate(24, (h) => h == 9 ? 3 : 0));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 480, height: 28,
          child: HeatmapGrid(matrix: matrix, onCellTap: (_, _) {}),
        ),
      ),
    ));
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
