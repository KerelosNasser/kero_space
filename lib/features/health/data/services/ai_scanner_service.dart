import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AiScannerService {
  final Dio _dio;

  AiScannerService(this._dio);

  Future<Ingredient?> scanFoodImage(String base64Image) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      debugPrint("OpenRouter API key missing or invalid in .env file.");
      return null;
    }

    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'meta-llama/llama-3.2-90b-vision-instruct',
          'response_format': { "type": "json_object" },
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this food image. Estimate its macronutrients per 100g and return ONLY a valid JSON object with EXACTLY this schema: {"name": "Food Name", "calories": 150, "protein": 10.5, "carbs": 20.0, "fat": 5.0, "isFastingCompliant": true}. Do not use markdown blocks, just the raw JSON.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ]
        }
      );

      if (response.statusCode == 200) {
        String content = response.data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        final json = jsonDecode(content);
        
        return Ingredient()
          ..deviceId = 'local'
          ..platform = 'ai'
          ..name = json['name'] ?? 'Analyzed Food'
          ..calories = (json['calories'] ?? 0).toDouble()
          ..protein = (json['protein'] ?? 0).toDouble()
          ..carbs = (json['carbs'] ?? 0).toDouble()
          ..fat = (json['fat'] ?? 0).toDouble()
          ..isFastingCompliant = json['isFastingCompliant'] ?? false;
      }
      return null;
    } catch (e) {
      debugPrint("AI Scan Error: $e");
      return null;
    }
  }
}
