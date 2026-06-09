import 'package:flutter/material.dart';
import '../../data/models/mass_attendance.dart';

class AttendanceContributionGrid extends StatelessWidget {
  final List<MassAttendance> attendances;

  const AttendanceContributionGrid({super.key, required this.attendances});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: CustomPaint(
        painter: _ContributionGridPainter(attendances),
      ),
    );
  }
}

class _ContributionGridPainter extends CustomPainter {
  final List<MassAttendance> attendances;

  _ContributionGridPainter(this.attendances);

  @override
  void paint(Canvas canvas, Size size) {
    final Map<DateTime, AttendanceType> attendanceMap = {};
    for (var att in attendances) {
      final normalizedDate = DateTime(att.date.year, att.date.month, att.date.day);
      attendanceMap[normalizedDate] = att.attendanceType;
    }

    final double cellSpacing = 2.0;
    final int rows = 7;
    final int cols = 52;
    
    final double cellWidth = (size.width - (cellSpacing * (cols - 1))) / cols;
    final double cellHeight = (size.height - (cellSpacing * (rows - 1))) / rows;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(Duration(days: cols * rows - 1));

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        final int daysOffset = (col * rows) + row;
        final DateTime currentDate = startDate.add(Duration(days: daysOffset));
        final DateTime normalizedCurrent = DateTime(currentDate.year, currentDate.month, currentDate.day);

        final AttendanceType? type = attendanceMap[normalizedCurrent];
        
        if (type == null) {
          paint.color = const Color(0xFF2C2C2E); // --bg-elevated
        } else if (type == AttendanceType.liturgy) {
          paint.color = const Color(0xFFBF5AF2).withValues(alpha: 1.0); // --accent-violet 100%
        } else if (type == AttendanceType.vespers) {
          paint.color = const Color(0xFFBF5AF2).withValues(alpha: 0.7); // --accent-violet 70%
        }

        final double x = col * (cellWidth + cellSpacing);
        final double y = row * (cellHeight + cellSpacing);

        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cellWidth, cellHeight), const Radius.circular(2)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContributionGridPainter oldDelegate) {
    return oldDelegate.attendances != attendances;
  }
}
