import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                          color: Colors.grey.withValues(alpha: 0.3),
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
    if (state is VoiceWakeDetected) {
      return Column(
        children: [
          const VoiceWaveform(isListening: false),
          const SizedBox(height: 16),
          Text(
            "Hey Kero detected...",
            style: Theme.of(context).textTheme.titleMedium,
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
            style: Theme.of(context).textTheme.titleLarge,
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
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            state.text,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (state is VoiceConfirmPending) {
      return Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(
            "Confirm Action",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _getIntentDescription(state.intent),
            style: Theme.of(context).textTheme.bodyLarge,
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
          const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      );
    }

    if (state is VoiceFailure) {
      return Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          Text(
            state.errorMessage,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (state.rawText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Heard: \"${state.rawText}\"",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
