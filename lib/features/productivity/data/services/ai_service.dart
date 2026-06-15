import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

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

  /// Auto-schedules tasks by evaluating a list of tasks and finding suitable start/end times.
  /// Note: In a real implementation, this would pass free calendar slots.
  Future<Map<int, DateTime>> autoScheduleTasks(List<Map<String, dynamic>> tasks) async {
    // For MVP, we simulate scheduling based on the current time + staggered hours
    final Map<int, DateTime> schedule = {};
    DateTime currentSlot = DateTime.now().add(const Duration(hours: 1));
    
    for (var task in tasks) {
      final id = task['id'] as int;
      schedule[id] = currentSlot;
      // Add 1 hour per task
      currentSlot = currentSlot.add(const Duration(hours: 1));
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
}
