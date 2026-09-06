import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';

import '../../../../core/di/injection.dart';
import '../../domain/parsed_intent.dart';
import '../bloc/voice_bloc.dart';
import '../bloc/voice_event.dart';
import '../bloc/voice_state.dart';
import 'command_hint_ticker.dart';
import 'voice_waveform.dart';

class VoiceBottomSheet extends StatelessWidget {
  const VoiceBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the VoiceBloc to the sheet
    return BlocProvider.value(
      value: getIt<VoiceBloc>(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.5,
        builder: (context, scrollController) {
          final colors = context.appColors;
          return Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: BlocConsumer<VoiceBloc, VoiceState>(
                listener: (context, state) {
                  if (state is VoiceIdle) {
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle at the top
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildStateContent(context, state),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, VoiceState state) {
    final colors = context.appColors;
    if (state is VoiceWakeDetected) {
      return Column(
        children: [
          const VoiceWaveform(isListening: false),
          const SizedBox(height: 16),
          Text(
            "Hey Kero detected...",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
        ],
      );
    }
    
    if (state is VoiceListening) {
      return Column(
        children: [
          const VoiceWaveform(isListening: true),
          const SizedBox(height: 16),
          Text(
            state.partialText.isEmpty ? "Listening..." : state.partialText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const CommandHintTicker(),
        ],
      );
    }

    if (state is VoiceProcessing) {
      return Column(
        children: [
          CircularProgressIndicator(color: colors.domainVoice),
          const SizedBox(height: 16),
          Text(
            state.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (state is VoiceConfirmPending) {
      return Column(
        children: [
          Icon(Icons.check_circle_outline, color: colors.accentSuccess, size: 48),
          const SizedBox(height: 16),
          Text(
            "Confirm Action",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _getIntentDescription(state.intent),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.read<VoiceBloc>().add(CancelIntentEvent()),
                icon: const Icon(Icons.close),
                label: const Text("Cancel"),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colors.accentSuccess),
                onPressed: () => context.read<VoiceBloc>().add(ConfirmIntentEvent()),
                icon: const Icon(Icons.check),
                label: const Text("Confirm"),
              ),
            ],
          )
        ],
      );
    }

    if (state is VoiceSuccess) {
      return Column(
        children: [
          Icon(Icons.check_circle, color: colors.accentSuccess, size: 64),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.textPrimary),
          ),
        ],
      );
    }

    if (state is VoiceFailure) {
      return Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.accentWarning, size: 48),
          const SizedBox(height: 16),
          Text(
            state.errorMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (state.rawText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Heard: \"${state.rawText}\"",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => context.read<VoiceBloc>().add(CancelIntentEvent()),
                child: const Text("Dismiss"),
              ),
              FilledButton(
                onPressed: () => context.read<VoiceBloc>().add(StartListeningEvent()),
                child: const Text("Try Again"),
              ),
            ],
          )
        ],
      );
    }

    return const SizedBox.shrink();
  }

  String _getIntentDescription(ParsedIntent intent) {
    if (intent is AddTodoIntent) {
      final rec = intent.recurrence != null ? " • ${intent.recurrence!.name}" : "";
      return "Add Todo: ${intent.title}$rec";
    }
    if (intent is AddNoteIntent) return "Add Note: ${intent.body}";
    if (intent is AddExpenseIntent) return "Add Expense: ${intent.amount} ${intent.vendor ?? ''}";
    if (intent is LogMealIntent) return "Log Meal: ${intent.grams != null ? '${intent.grams}g ' : ''}${intent.food}";
    if (intent is MarkAttendanceIntent) return "Mark Church Attendance";
    if (intent is BlockAppIntent) return "Block App: ${intent.appName}";
    if (intent is NavigateIntent) return "Navigate to ${intent.destination}";
    return "Unknown Intent";
  }
}
