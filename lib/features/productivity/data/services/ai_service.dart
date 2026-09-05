import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import '../../../../core/data/isar_service.dart';
import '../models/productivity_collections.dart';

class AIService {
  final Dio _dio;
  
  String get _openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? ''; 

  AIService() : _dio = Dio();

  /// Infers the energy level (1=Low, 2=Medium, 3=High) of a task based on its title.
  Future<int> inferEnergyLevel(String taskTitle) async {
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free', // Using OpenRouter

          'messages': [
            {'role': 'system', 'content': 'You are a productivity assistant. Classify the energy level required to complete the user\'s task as either 1 (Low energy/easy), 2 (Medium energy), or 3 (High energy/hard focus). Respond ONLY with the number 1, 2, or 3.'},
            {'role': 'user', 'content': taskTitle}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      return int.tryParse(reply) ?? 2; // Default to medium if parsing fails
    } catch (e) {
      debugPrint('AI Service Error (inferEnergyLevel): $e');
      return 2;
    }
  }

  /// Breaks down a project goal into a list of actionable sub-tasks with inferred energy levels,
  /// or asks a clarifying question if the prompt is too vague.
  Future<dynamic> breakdownProject(String projectDescription) async {
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openRouterApiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
        data: {
          'model': 'openai/gpt-oss-120b:free', 
          'messages': [
            {
              'role': 'system', 
              'content': '''You are a strict productivity assistant. Your job is to break down the user's project into 3-5 immediate, actionable sub-tasks. 
If the user's prompt is vague, lacks detail, or is just a broad concept (e.g. "Build an app", "clash of clans clone", "make a website"), you MUST ask a clarifying question to structure the idea instead of guessing.

Output ONLY valid JSON in one of these two formats, with NO markdown formatting:
Format 1 (Clarification):
{"type": "clarification", "question": "What core mechanics do you want to start with for your clone?"}

Format 2 (Plan):
{"type": "plan", "icon": "🚀", "title": "Project Title", "subtasks": [{"title": "Step 1", "energyLevel": 1}, ...]}
energyLevel must be 1 (Low), 2 (Medium), or 3 (High).'''
            },
            {'role': 'user', 'content': projectDescription}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      final cleanReply = reply.replaceAll('```json', '').replaceAll('```', '');
      
      final dynamic parsed = jsonDecode(cleanReply);
      return parsed;
    } catch (e) {
      debugPrint('AI Service Error (breakdownProject): $e');
      // Fallback response
      return {
        "type": "plan",
        "icon": "📝",
        "title": projectDescription.length > 20 ? projectDescription.substring(0, 20) : projectDescription,
        "subtasks": [
          {'title': 'Draft initial plan', 'energyLevel': 2},
          {'title': 'Execute step 1', 'energyLevel': 3},
        ]
      };
    }
  }

  /// Auto-schedules tasks by finding real, non-conflicting time slots across
  /// working hours (09:00 - 18:00), respecting existing calendar events and scheduled tasks.
  Future<Map<int, DateTime>> autoScheduleTasks(
    List<Map<String, dynamic>> tasks, {
    DateTime? referenceDate,
    List<DateTimeRange>? customBusySlots,
  }) async {
    final Map<int, DateTime> schedule = {};
    if (tasks.isEmpty) return schedule;

    final List<DateTimeRange> busy = [];
    if (customBusySlots != null) {
      busy.addAll(customBusySlots);
    }

    // Query existing scheduled tasks & calendar events if Isar is available
    if (IsarService.isInitialized) {
      final isar = IsarService.instance;
      final existingTasks = await isar.tasks.where().findAll();
      for (final t in existingTasks) {
        if (t.dueDate != null) {
          busy.add(DateTimeRange(
            start: t.dueDate!,
            end: t.dueDate!.add(const Duration(minutes: 45)),
          ));
        }
      }

      final existingEvents = await isar.calendarEvents.where().findAll();
      for (final ev in existingEvents) {
        busy.add(DateTimeRange(start: ev.startTime, end: ev.endTime));
      }
    }

    final base = referenceDate ?? DateTime.now();
    DateTime cursor = DateTime(base.year, base.month, base.day, 9, 0);
    if (cursor.isBefore(base)) {
      cursor = DateTime(base.year, base.month, base.day, base.hour + 1, 0);
    }

    // Sort tasks so high energy (3) gets earlier slots
    final sortedTasks = List<Map<String, dynamic>>.from(tasks)
      ..sort((a, b) => ((b['energyLevel'] as int?) ?? 2)
          .compareTo((a['energyLevel'] as int?) ?? 2));

    for (final task in sortedTasks) {
      final id = task['id'] as int;
      final energy = (task['energyLevel'] as int?) ?? 2;
      final durationMinutes = energy == 3 ? 60 : (energy == 2 ? 45 : 30);

      // Find first slot between 09:00 and 18:00 without collision
      DateTime candidate = cursor;
      bool slotFound = false;

      while (!slotFound) {
        // Enforce daily work hours 9 AM to 6 PM
        if (candidate.hour >= 18) {
          // Move to next day at 9:00 AM
          candidate =
              DateTime(candidate.year, candidate.month, candidate.day + 1, 9, 0);
        } else if (candidate.hour < 9) {
          candidate =
              DateTime(candidate.year, candidate.month, candidate.day, 9, 0);
        }

        final candidateEnd = candidate.add(Duration(minutes: durationMinutes));
        final candidateRange = DateTimeRange(start: candidate, end: candidateEnd);

        final hasConflict = busy.any((b) =>
            candidateRange.start.isBefore(b.end) &&
            candidateRange.end.isAfter(b.start));

        if (!hasConflict) {
          slotFound = true;
          schedule[id] = candidate;
          busy.add(candidateRange);
          // Advance cursor for next task with 15 min buffer
          cursor = candidateEnd.add(const Duration(minutes: 15));
        } else {
          // Conflict: advance candidate by 30 minutes and recheck
          candidate = candidate.add(const Duration(minutes: 30));
        }
      }
    }

    return schedule;
  }
  /// Generates a short title (2-4 words) for a note based on its content.
  Future<String> generateNoteTitle(String content) async {
    if (content.trim().isEmpty) return "New Note";
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant. Generate a concise, catchy title (maximum 4 words) for the following note content. Output ONLY the title, no quotes or extra text.'},
            {'role': 'user', 'content': content.length > 500 ? content.substring(0, 500) : content}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      return reply.replaceAll('"', '');
    } catch (e) {
      debugPrint('AI Service Error (generateNoteTitle): $e');
      return "Untitled Note";
    }
  }

  /// Analyzes text content and maps it to existing tasks or projects.
  Future<List<int>> extractLinkedEntityIds(String content, List<Map<String, dynamic>> availableEntities) async {
    if (content.trim().isEmpty || availableEntities.isEmpty) return [];
    try {
      final entitiesJson = jsonEncode(availableEntities.map((e) => {"id": e["id"], "title": e["title"]}).toList());
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {'role': 'system', 'content': 'You are a strict data mapper. Match the user\'s note content to the provided JSON list of tasks/projects. Return ONLY a JSON array of integers representing the IDs of the related tasks/projects. E.g. [1, 5]. If none match, return [].'},
            {'role': 'user', 'content': 'Available entities: $entitiesJson\n\nNote content: $content'}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      final cleanReply = reply.replaceAll('```json', '').replaceAll('```', '');
      
      final List<dynamic> parsed = jsonDecode(cleanReply);
      return parsed.cast<int>();
    } catch (e) {
      debugPrint('AI Service Error (extractLinkedEntityIds): $e');
      return [];
    }
  }

  /// Answers general developer and life-OS queries from the Command Palette.
  Future<String> askGeneralQuestion(String prompt) async {
    if (prompt.trim().isEmpty) return "Please enter a question or command.";
    if (_openRouterApiKey.isEmpty) {
      return "OpenRouter API key is not configured in .env. Please add OPENROUTER_API_KEY.";
    }
    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_openRouterApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'openai/gpt-oss-120b:free',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Trobio Assistant, an ultra-smart, pragmatic assistant embedded in a personal developer life-OS. Provide direct, high-signal, concise answers without fluff. Format with bullet points or code snippets when helpful.'
            },
            {'role': 'user', 'content': prompt}
          ],
        },
      );

      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      return reply.isNotEmpty ? reply : "No response generated.";
    } catch (e) {
      debugPrint('AI Service Error (askGeneralQuestion): $e');
      return "Network or API error: $e";
    }
  }
}

