import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handles AI-powered finance operations (transaction parsing & advice).
///
/// All calls go through OpenRouter API. No network data is persisted locally.
class FinanceAIService {
  final Dio _dio;

  FinanceAIService({Dio? dio}) : _dio = dio ?? Dio();

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Parses a free-text message into transaction fields via the AI model.
  /// Returns a map with keys: amount, type, category, vendor, sourceName.
  Future<Map<String, dynamic>> quickLogTransaction(String text) async {
    final res = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': 'openai/gpt-oss-120b:free',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a strict transaction parser. Analyze the user\'s message and parse it into transaction properties. Respond ONLY with a JSON object, no markdown blocks. Structure:\n{"amount": double, "type": "INCOME"|"EXPENSE", "category": "Dining"|"Transport"|"Groceries"|"Salary"|"Other", "vendor": "name or null", "sourceName": "matched bank or source name or null"}',
          },
          {'role': 'user', 'content': text},
        ],
      },
    );

    final raw = res.data['choices'][0]['message']['content'] as String;
    final clean = raw.trim().replaceAll('```json', '').replaceAll('```', '');
    return jsonDecode(clean) as Map<String, dynamic>;
  }

  /// Generates a short financial advice paragraph based on recent transactions & subscriptions.
  Future<String> refreshAdvice({
    required String transactionSummary,
    required String subscriptionSummary,
  }) async {
    final res = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': 'openai/gpt-oss-120b:free',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a financial advisor. Write a single short paragraph (maximum 3 sentences) giving the user highly specific financial advice or highlights of their budget. Keep it concise, friendly, and practical.',
          },
          {
            'role': 'user',
            'content': 'My recent transactions: $transactionSummary. My subscriptions: $subscriptionSummary.',
          },
        ],
      },
    );

    return (res.data['choices'][0]['message']['content'] as String).trim();
  }
}
