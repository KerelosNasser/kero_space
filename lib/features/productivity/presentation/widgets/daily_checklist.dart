import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';

import '../../data/models/productivity_collections.dart';
import '../bloc/productivity_bloc.dart';
import 'package:kero_space/core/app_theme.dart';

class DailyChecklist extends StatelessWidget {
  final List<Task> tasks;

  const DailyChecklist({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks due today. Great job!"));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return TaskRow(task: tasks[index]);
      },
    );
  }
}

class TaskRow extends StatefulWidget {
  final Task task;

  const TaskRow({super.key, required this.task});

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not completed, show the breathing gradient
    final bool isFocusTask = !widget.task.isCompleted;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isFocusTask ? LinearGradient(
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withValues(alpha: 0.5 + (_breathingAnimation.value * 0.5)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ) : null,
                color: isFocusTask ? null : Theme.of(context).cardColor.withValues(alpha: 0.4),
                boxShadow: isFocusTask ? [
                  BoxShadow(
                    color: AppTheme.textPrimary.withValues(alpha: _breathingAnimation.value * 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ] : [],
              ),
              child: child,
            );
          },
          child: ListTile(
            leading: Checkbox(
              value: widget.task.isCompleted,
              onChanged: (val) {
                if (val == true) {
                  HapticFeedback.lightImpact();
                  _confettiController.play();
                  context.read<ProductivityBloc>().add(ProductivityEvent.completeTask(widget.task.id));
                } else {
                  HapticFeedback.selectionClick();
                  // No un-complete logic right now, but could be added
                }
              },
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                color: widget.task.isCompleted ? AppTheme.textSecondary : null,
              ),
            ),
            subtitle: widget.task.description != null ? Text(widget.task.description!) : null,
            trailing: isFocusTask ? const Icon(Icons.star_border, size: 16, color: AppTheme.textSecondary) : const Icon(Icons.check, color: AppTheme.accentMint),
          ),
        ),
        Positioned(
          left: 40,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppTheme.accentMint, AppTheme.accentCyan, AppTheme.accentRose, AppTheme.accentGold, AppTheme.accentViolet],
            createParticlePath: drawStar,
            numberOfParticles: 15,
            emissionFrequency: 0.05,
          ),
        ),
      ],
    );
  }

  Path drawStar(Size size) {
    // Basic star path
    double degToRad(double deg) => deg * (3.141592653589793 / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * 1 * (step).cos(),
          halfWidth + externalRadius * 1 * (step).sin());
      path.lineTo(halfWidth + internalRadius * 1 * (step + halfDegreesPerStep).cos(),
          halfWidth + internalRadius * 1 * (step + halfDegreesPerStep).sin());
    }
    path.close();
    return path;
  }
}

// Helper extension
extension NumTrig on num {
  double cos() => math.cos(this);
  double sin() => math.sin(this);
}
