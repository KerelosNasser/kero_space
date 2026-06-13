import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/voice/domain/command_parser.dart';
import 'package:kero_space/features/voice/domain/parsed_intent.dart';
import 'package:kero_space/features/voice/domain/recurrence.dart';

void main() {
  late CommandParser parser;

  setUp(() {
    parser = CommandParser();
  });

  group('Normalization', () {
    test('normalizes numbers and trigger variants', () {
      expect(parser.normalize("fifty EGP"), "50 egp");
      expect(parser.normalize("two hundred"), "200");
      expect(parser.normalize("to do shower"), "todo shower");
      expect(parser.normalize("um to-do shower"), "todo shower");
      expect(parser.normalize("like take a note"), "take a note");
    });
  });

  group('Productivity Intents', () {
    test('AddTodoIntent - prefix', () {
      final intent = parser.parse("todo shower daily");
      expect(intent, isA<AddTodoIntent>());
      expect((intent as AddTodoIntent).title, "shower");
      expect(intent.recurrence, Recurrence.daily);
    });

    test('AddTodoIntent - NL fallback', () {
      final intent = parser.parse("remind me to call mom every week");
      expect(intent, isA<AddTodoIntent>());
      expect((intent as AddTodoIntent).title, "call mom");
      expect(intent.recurrence, Recurrence.weekly);
    });

    test('AddNoteIntent', () {
      final intent = parser.parse("note buy some milk");
      expect(intent, isA<AddNoteIntent>());
      expect((intent as AddNoteIntent).body, "buy some milk");
      
      final nlIntent = parser.parse("take a note buy some milk");
      expect(nlIntent, isA<AddNoteIntent>());
      expect((nlIntent as AddNoteIntent).body, "buy some milk");
    });
  });

  group('Finance Intents', () {
    test('AddExpenseIntent', () {
      final intent = parser.parse("expense 200 groceries");
      expect(intent, isA<AddExpenseIntent>());
      expect((intent as AddExpenseIntent).amount, 200.0);
      expect(intent.vendor, "groceries");
      
      final nlIntent = parser.parse("i spent 50 on coffee");
      expect(nlIntent, isA<AddExpenseIntent>());
      expect((nlIntent as AddExpenseIntent).amount, 50.0);
      expect(nlIntent.vendor, "coffee");
    });
  });

  group('Health Intents', () {
    test('LogMealIntent', () {
      final intent = parser.parse("meal 200g chicken");
      expect(intent, isA<LogMealIntent>());
      expect((intent as LogMealIntent).food, "chicken");
      expect(intent.grams, 200);

      final nlIntent = parser.parse("i ate an apple");
      expect(nlIntent, isA<LogMealIntent>());
      expect((nlIntent as LogMealIntent).food, "an apple");
    });
  });
  
  group('Church Intents', () {
    test('MarkAttendanceIntent', () {
      final intent = parser.parse("mark attendance");
      expect(intent, isA<MarkAttendanceIntent>());
      
      final nlIntent = parser.parse("i went to mass");
      expect(nlIntent, isA<MarkAttendanceIntent>());
    });
  });

  group('Unknown Intent', () {
    test('UnknownIntent', () {
      final intent = parser.parse("hello there");
      expect(intent, isA<UnknownIntent>());
    });
  });
}
