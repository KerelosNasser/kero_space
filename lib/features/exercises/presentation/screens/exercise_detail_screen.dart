import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/di/injection.dart';
import '../bloc/exercise_bloc.dart';
import '../../data/repositories/exercises_repository.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final WorkoutExerciseViewModel exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  static double calculate1RM(double weight, int reps) {
    if (weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    // Epley formula: w * (1 + r / 30)
    return weight * (1.0 + (reps / 30.0));
  }

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();

  int _restDurationSeconds = 90;
  int _remainingRestSeconds = 0;
  Timer? _restTimer;

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _startRestTimer([int? seconds]) {
    _restTimer?.cancel();
    setState(() {
      _remainingRestSeconds = seconds ?? _restDurationSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingRestSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingRestSeconds = 0;
        });
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rest finished! Ready for the next set.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _remainingRestSeconds--;
        });
      }
    });
  }

  void _adjustRestTimer(int deltaSeconds) {
    setState(() {
      _remainingRestSeconds = (_remainingRestSeconds + deltaSeconds).clamp(0, 600);
      if (_remainingRestSeconds == 0) {
        _restTimer?.cancel();
      }
    });
  }

  void _cancelRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _remainingRestSeconds = 0;
    });
  }

  String _formatRestTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _submitSet(BuildContext context, WorkoutExerciseViewModel exercise) {
    final colors = context.appColors;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid reps')),
      );
      return;
    }

    final nextSet = exercise.nextSetNumber;

    context.read<ExerciseBloc>().add(
          LogExerciseSet(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            setNumber: nextSet,
            reps: reps,
            weight: weight,
          ),
        );

    _weightController.clear();
    _repsController.clear();

    _startRestTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Set $nextSet logged! Rest timer started.'),
        backgroundColor: colors.accentSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    ExerciseBloc bloc;
    try {
      bloc = context.read<ExerciseBloc>();
    } catch (_) {
      bloc = getIt<ExerciseBloc>();
    }

    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<ExerciseBloc, ExerciseState>(
        builder: (context, state) {
          final exercise = state.todayWorkout?.exercises.firstWhere(
                (e) => e.id == widget.exercise.id,
                orElse: () => widget.exercise,
              ) ??
              widget.exercise;

          final maxWeight = exercise.loggedSets.isEmpty
              ? 0.0
              : exercise.loggedSets
                  .map((s) => s.weight)
                  .reduce((a, b) => a > b ? a : b);
          final totalReps = exercise.loggedSets.fold<int>(0, (sum, s) => sum + s.reps);

          final est1RM = exercise.loggedSets.isEmpty
              ? 0.0
              : exercise.loggedSets
                  .map((s) => ExerciseDetailScreen.calculate1RM(s.weight, s.reps))
                  .reduce((a, b) => a > b ? a : b);

          return Scaffold(
            backgroundColor: colors.bgBase,
            appBar: AppBar(
              title: Text(
                exercise.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colors.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: colors.textPrimary),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata chips row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(
                  icon: Icons.category_rounded,
                  label: exercise.category.toUpperCase(),
                  color: colors.accentPrimary,
                ),
                _buildTag(
                  icon: Icons.fitness_center_rounded,
                  label: exercise.equipment,
                  color: colors.accentSecondary,
                ),
                _buildTag(
                  icon: Icons.repeat_rounded,
                  label: '${exercise.suggestedSets} Sets × ${exercise.targetReps}',
                  color: colors.accentWarning,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Performance stats overview card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Sets Done', '${exercise.loggedSets.length}', colors),
                  _buildStatItem('Max Weight', '${maxWeight.toStringAsFixed(1)} kg', colors),
                  _buildStatItem('Est. 1RM', '${est1RM.toStringAsFixed(1)} kg', colors),
                  _buildStatItem('Total Reps', '$totalReps', colors),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Rest Timer Card
            if (_remainingRestSeconds > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_rounded, color: colors.accentPrimary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'REST TIMER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: colors.accentPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _cancelRestTimer,
                          child: Text(
                            'Skip',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRestTime(_remainingRestSeconds),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _restDurationSeconds > 0
                          ? (_remainingRestSeconds / _restDurationSeconds).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: colors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [60, 90, 120, 180].map((sec) {
                        final isSelected = _restDurationSeconds == sec;
                        return ChoiceChip(
                          label: Text('${sec}s'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _restDurationSeconds = sec;
                                _remainingRestSeconds = sec;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _adjustRestTimer(-15),
                          child: const Text('-15s'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => _adjustRestTimer(30),
                          child: const Text('+30s'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Instructions card
            if (exercise.instructionsEn.isNotEmpty) ...[
              Text(
                'INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Text(
                  exercise.instructionsEn,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Quick Log Set Section
            Text(
              'LOG A NEW SET',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'e.g. 60.0',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            hintText: 'e.g. 10',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitSet(context, exercise),
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: Text('Log Set #${exercise.nextSetNumber}'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logged Sets History
            Text(
              'TODAY\'S LOGGED SETS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (exercise.loggedSets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Center(
                  child: Text(
                    'No sets logged for this exercise today.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercise.loggedSets.length,
                  separatorBuilder: (_, _) => Divider(
                    color: colors.borderSubtle,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final set = exercise.loggedSets[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: colors.accentPrimary.withValues(alpha: 0.15),
                        child: Text(
                          '${set.setNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.accentPrimary,
                          ),
                        ),
                      ),
                      title: Text(
                        '${set.weight} kg × ${set.reps} reps',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      trailing: Text(
                        '${set.loggedAt.hour.toString().padLeft(2, '0')}:${set.loggedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
        },
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, AppThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
