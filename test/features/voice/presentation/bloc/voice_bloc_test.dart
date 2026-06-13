import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kero_space/features/voice/presentation/bloc/voice_bloc.dart';
import 'package:kero_space/features/voice/presentation/bloc/voice_event.dart';
import 'package:kero_space/features/voice/presentation/bloc/voice_state.dart';
import 'package:kero_space/features/voice/domain/command_parser.dart';
import 'package:kero_space/features/voice/domain/parsed_intent.dart';

import 'package:kero_space/features/productivity/presentation/bloc/productivity_bloc.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:kero_space/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:kero_space/features/church/presentation/bloc/church_bloc.dart';

class MockCommandParser extends Mock implements CommandParser {}
class MockProductivityBloc extends Mock implements ProductivityBloc {}
class MockHealthBloc extends Mock implements HealthBloc {}
class MockFinanceBloc extends Mock implements FinanceBloc {}
class MockChurchBloc extends Mock implements ChurchBloc {}

void main() {
  late VoiceBloc voiceBloc;
  late MockCommandParser mockParser;
  late MockProductivityBloc mockProductivityBloc;
  late MockHealthBloc mockHealthBloc;
  late MockFinanceBloc mockFinanceBloc;
  late MockChurchBloc mockChurchBloc;

  setUpAll(() {
    registerFallbackValue(const ProductivityEvent.loadData());
    // Since we mock the blocs, we don't really need to define all fallback values unless we use any() in verify
  });

  setUp(() {
    mockParser = MockCommandParser();
    mockProductivityBloc = MockProductivityBloc();
    mockHealthBloc = MockHealthBloc();
    mockFinanceBloc = MockFinanceBloc();
    mockChurchBloc = MockChurchBloc();

    voiceBloc = VoiceBloc(
      mockParser,
      mockProductivityBloc,
      mockHealthBloc,
      mockFinanceBloc,
      mockChurchBloc,
    );
  });

  tearDown(() {
    voiceBloc.close();
  });

  group('VoiceBloc Intent Dispatch', () {
    test('initial state is VoiceIdle', () {
      expect(voiceBloc.state, isA<VoiceIdle>());
    });

    blocTest<VoiceBloc, VoiceState>(
      'emits [VoiceConfirmPending, VoiceSuccess, VoiceIdle] and calls ProductivityBloc for AddTodoIntent',
      build: () {
        when(() => mockParser.parse('add task buy milk'))
            .thenReturn(const AddTodoIntent(title: 'buy milk'));
        return voiceBloc;
      },
      seed: () => const VoiceConfirmPending(AddTodoIntent(title: 'buy milk')),
      act: (bloc) => bloc.add(ConfirmIntentEvent()),
      expect: () => [
        isA<VoiceSuccess>().having((s) => s.message, 'message', 'Added to do'),
        isA<VoiceIdle>(),
      ],
      verify: (_) {
        verify(() => mockProductivityBloc.add(any(that: isA<ProductivityEvent>()))).called(1);
      },
    );
    
    blocTest<VoiceBloc, VoiceState>(
      'emits [VoiceSuccess, VoiceIdle] and calls HealthBloc for LogMealIntent',
      build: () {
        return voiceBloc;
      },
      seed: () => const VoiceConfirmPending(LogMealIntent(food: 'chicken', grams: 200)),
      act: (bloc) => bloc.add(ConfirmIntentEvent()),
      expect: () => [
        isA<VoiceSuccess>().having((s) => s.message, 'message', 'Meal logged'),
        isA<VoiceIdle>(),
      ],
      verify: (_) {
        verify(() => mockHealthBloc.add(any(that: isA<LogMeal>()))).called(1);
      },
    );
  });
}
