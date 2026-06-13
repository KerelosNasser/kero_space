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

    return normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  ParsedIntent parse(String rawText) {
    final text = normalize(rawText);

    // 1. Productivity — Todo
    if (text.startsWith('todo ') || text.startsWith('task ')) {
      final content = text.replaceFirst(RegExp(r'^(todo|task)\s+'), '');
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
      final content = text.replaceFirst(RegExp(r'^(take a note|write down|jot down)\s+'), '');
      return AddNoteIntent(body: content);
    }

    // 3. Finance — Expense
    if (text.startsWith('expense ') || text.startsWith('spent ')) {
      return _parseExpense(text.replaceFirst(RegExp(r'^(expense|spent)\s+'), ''));
    }
    if (text.startsWith('i spent ')) {
      return _parseExpense(text.replaceFirst('i spent ', ''));
    }

    // 4. Health — Meal
    if (text.startsWith('meal ') || text.startsWith('log ') || text.startsWith('ate ')) {
      return _parseMeal(text.replaceFirst(RegExp(r'^(meal|log|ate)\s+'), ''));
    }
    if (text.startsWith('i ate ') || text.startsWith('i had ')) {
      return _parseMeal(text.replaceFirst(RegExp(r'^(i ate|i had)\s+'), ''));
    }

    // 5. Church — Attendance
    if (text.contains('mark attendance') || text.contains('went to mass') || text.contains('attended church')) {
      return MarkAttendanceIntent(date: DateTime.now());
    }

    // 6. Navigation
    if (text.startsWith('open ') || text.startsWith('show ') || text.startsWith('go to ')) {
      return NavigateIntent(destination: text.replaceFirst(RegExp(r'^(open|show|go to)\s+'), ''));
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
    final regex = RegExp(r'^([\d\.]+)\s+(?:on\s+)?(.+)$');
    final match = regex.firstMatch(content);
    if (match != null) {
      return AddExpenseIntent(
        amount: double.tryParse(match.group(1)!) ?? 0.0,
        vendor: match.group(2),
      );
    }
    // Fallback: just amount
    final amountOnlyRegex = RegExp(r'^([\d\.]+)$');
    final matchOnly = amountOnlyRegex.firstMatch(content);
    if (matchOnly != null) {
      return AddExpenseIntent(amount: double.tryParse(matchOnly.group(1)!) ?? 0.0, vendor: null);
    }
    return AddExpenseIntent(amount: 0.0, vendor: content);
  }

  LogMealIntent _parseMeal(String content) {
    // Look for "GRAMSg FOOD" or "GRAMS grams of FOOD"
    final regex = RegExp(r'^(\d+)\s*(?:g|grams(?:\s+of)?)\s+(.+)$');
    final match = regex.firstMatch(content);
    if (match != null) {
      return LogMealIntent(
        grams: int.tryParse(match.group(1)!),
        food: match.group(2)!,
      );
    }
    return LogMealIntent(food: content, grams: null);
  }
}
