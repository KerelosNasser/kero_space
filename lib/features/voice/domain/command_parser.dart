import 'package:injectable/injectable.dart';

import 'parsed_intent.dart';
import 'recurrence.dart';

@lazySingleton
class CommandParser {
  final Map<String, String> _numberWords = {
    'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
    'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    'ten': '10', 'eleven': '11', 'twelve': '12', 'twenty': '20',
    'thirty': '30', 'forty': '40', 'fifty': '50', 'sixty': '60',
    'seventy': '70', 'eighty': '80', 'ninety': '90', 'hundred': '100',
    'two hundred': '200', 'three hundred': '300', 'four hundred': '400',
    'five hundred': '500'
  };

  final List<String> _fillers = [' um ', ' uh ', ' like ', ' you know '];

  static final _whitespaceRegex = RegExp(r'\s+');
  static final _todoPrefixRegex = RegExp(r'^(todo|task)\s+');
  static final _notePrefixRegex = RegExp(r'^(take a note|write down|jot down)\s+');
  static final _expensePrefixRegex = RegExp(r'^(expense|spent)\s+');
  static final _mealPrefixRegex = RegExp(r'^(meal|log|ate)\s+');
  static final _navPrefixRegex = RegExp(r'^(open|show|go to)\s+');
  static final _expenseRegex = RegExp(r'^([\d\.]+)\s+(?:on\s+)?(.+)$');
  static final _expenseAmountOnlyRegex = RegExp(r'^([\d\.]+)$');
  static final _mealRegex = RegExp(r'^([\d\.]+)\s*(?:g|grams(?:\s+of)?)\s+(.+)$');

  String normalize(String raw) {
    String normalized = raw.toLowerCase();
    
    // Remove fillers
    for (final filler in _fillers) {
      normalized = normalized.replaceAll(filler, ' ');
    }
    if (normalized.startsWith('um ')) normalized = normalized.substring(3);
    if (normalized.startsWith('uh ')) normalized = normalized.substring(3);

    // Normalize trigger variants
    normalized = normalized.replaceAll('to do', 'todo');
    normalized = normalized.replaceAll('to-do', 'todo');
    normalized = normalized.replaceAll('todos', 'todo');

    // Replace number words with digits (simple version for V1)
    _numberWords.forEach((word, digit) {
      normalized = normalized.replaceAll(RegExp(r'\b' + word + r'\b'), digit);
    });

    return normalized.trim().replaceAll(_whitespaceRegex, ' ');
  }

  ParsedIntent parse(String rawText) {
    final text = normalize(rawText);

    // 1. Productivity — Todo
    if (text.startsWith('todo ') || text.startsWith('task ')) {
      final content = text.replaceFirst(_todoPrefixRegex, '');
      return _parseTodo(content);
    }
    if (text.startsWith('remind me to ')) {
      final content = text.replaceFirst('remind me to ', '');
      return _parseTodo(content);
    }

    // 2. Productivity — Note
    if (text.startsWith('note ')) {
      return AddNoteIntent(body: text.replaceFirst('note ', ''));
    }
    if (text.startsWith('take a note ') || text.startsWith('write down ') || text.startsWith('jot down ')) {
      final content = text.replaceFirst(_notePrefixRegex, '');
      return AddNoteIntent(body: content);
    }

    // 3. Finance — Expense
    if (text.startsWith('expense ') || text.startsWith('spent ')) {
      return _parseExpense(text.replaceFirst(_expensePrefixRegex, ''));
    }
    if (text.startsWith('i spent ')) {
      return _parseExpense(text.replaceFirst('i spent ', ''));
    }

    // 4. Health — Meal
    if (text.startsWith('meal ') || text.startsWith('log ') || text.startsWith('ate ')) {
      return _parseMeal(text.replaceFirst(_mealPrefixRegex, ''));
    }
    if (text.startsWith('i ate ') || text.startsWith('i had ')) {
      return _parseMeal(text.replaceFirst(RegExp(r'^(i ate|i had)\s+'), ''));
    }

    // 5. Church — Attendance
    if (text.contains('mark') &&
        (text.contains('mass') || text.contains('liturgy'))) {
      return MarkAttendanceIntent(date: DateTime.now());
    }
    if (text.contains('mark attendance') ||
        text.contains('went to mass') ||
        text.contains('attended church')) {
      return MarkAttendanceIntent(date: DateTime.now());
    }
    if (text.contains('streak') || text.contains('church streak')) {
      return NavigateIntent(destination: 'church');
    }

    // 6. Navigation
    if (text.startsWith('open ') || text.startsWith('show ') || text.startsWith('go to ')) {
      return NavigateIntent(destination: text.replaceFirst(_navPrefixRegex, ''));
    }

    // 7. Telemetry — Block App
    if (text.startsWith('block ')) {
      return BlockAppIntent(appName: text.replaceFirst('block ', ''));
    }

    return UnknownIntent(raw: rawText);
  }

  AddTodoIntent _parseTodo(String content) {
    Recurrence? recurrence;
    String title = content;
    
    if (content.endsWith(' daily') || content.endsWith(' every day')) {
      recurrence = Recurrence.daily;
      title = content.replaceAll(RegExp(r'\s+(daily|every day)$'), '');
    } else if (content.endsWith(' weekly') || content.endsWith(' every week')) {
      recurrence = Recurrence.weekly;
      title = content.replaceAll(RegExp(r'\s+(weekly|every week)$'), '');
    } else if (content.endsWith(' monthly') || content.endsWith(' every month')) {
      recurrence = Recurrence.monthly;
      title = content.replaceAll(RegExp(r'\s+(monthly|every month)$'), '');
    }

    return AddTodoIntent(title: title, recurrence: recurrence);
  }

  AddExpenseIntent _parseExpense(String content) {
    // Look for "AMOUNT on CATEGORY" or "AMOUNT CATEGORY"
    final match = _expenseRegex.firstMatch(content);
    if (match != null) {
      return AddExpenseIntent(
        amount: double.tryParse(match.group(1)!) ?? 0.0,
        vendor: match.group(2),
      );
    }
    // Fallback: just amount
    final matchOnly = _expenseAmountOnlyRegex.firstMatch(content);
    if (matchOnly != null) {
      return AddExpenseIntent(amount: double.tryParse(matchOnly.group(1)!) ?? 0.0, vendor: null);
    }
    return AddExpenseIntent(amount: 0.0, vendor: content);
  }

  LogMealIntent _parseMeal(String content) {
    // Look for "GRAMSg FOOD" or "GRAMS grams of FOOD"
    final match = _mealRegex.firstMatch(content);
    if (match != null) {
      return LogMealIntent(
        grams: double.tryParse(match.group(1)!),
        food: match.group(2)!,
      );
    }
    return LogMealIntent(food: content, grams: null);
  }
}
