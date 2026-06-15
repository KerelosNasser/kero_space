import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  final Dio _dio;
  
  String get _openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? ''; 
  String get _nimApiKey => dotenv.env['NIM_API_KEY'] ?? '';

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
          'model': 'nvidia/nemotron-3-ultra-550b-a55b:free', // Using OpenRouter

          'messages': [
            {'role': 'system', 'content': 'You are a productivity assistant. Classify the energy level required to complete the user\'s task as either 1 (Low energy/easy), 2 (Medium energy), or 3 (High energy/hard focus). Respond ONLY with the number 1, 2, or 3.'},
            {'role': 'user', 'content': taskTitle}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      return int.tryParse(reply) ?? 2; // Default to medium if parsing fails
    } catch (e) {
      print('AI Service Error (inferEnergyLevel): $e');
      return 2;
    }
  }

  /// Breaks down a project goal into a list of actionable sub-tasks with inferred energy levels.
  Future<List<Map<String, dynamic>>> breakdownProject(String projectDescription) async {
    try {
      final response = await _dio.post(
        'https://integrate.api.nvidia.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $_nimApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'nvidia/nemotron-3-ultra-550b-a55b', 
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a strict productivity assistant. Break down the user\'s project into 3-5 immediate, actionable sub-tasks. Output ONLY valid JSON in this exact format, with no markdown formatting: [{"title": "Step 1", "energyLevel": 1}, ...]. energyLevel must be 1, 2, or 3.'
            },
            {'role': 'user', 'content': projectDescription}
          ],
        },
      );
      
      final reply = response.data['choices'][0]['message']['content'].toString().trim();
      final cleanReply = reply.replaceAll('```json', '').replaceAll('```', '');
      
      final List<dynamic> parsed = jsonDecode(cleanReply);
      return parsed.cast<Map<String, dynamic>>();
    } catch (e) {
      print('AI Service Error (breakdownProject): $e');
      // Fallback response
      return [
        {'title': 'Draft initial plan for: $projectDescription', 'energyLevel': 2},
        {'title': 'Execute step 1', 'energyLevel': 3},
      ];
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
}
