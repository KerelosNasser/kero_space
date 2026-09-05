import 'package:dio/dio.dart';
import '../models/coptic_day_info.dart';

class YouVersionService {
  final Dio dio;
  final String? apiKey;

  YouVersionService({required this.dio, this.apiKey});

  static const _baseUrl = 'https://api.youversion.com';

  String getPassageUrl(ScriptureReference ref) {
    final encoded = Uri.encodeComponent(ref.displayName);
    return 'https://www.bible.com/bible/1/$encoded';
  }

  Future<String?> getPassageText(ScriptureReference ref) async {
    if (apiKey == null || apiKey!.isEmpty) return null;
    try {
      final response = await dio.get(
        '$_baseUrl/bible/passage',
        queryParameters: {
          'q': ref.displayName,
          'version': '1', // NIV
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      return response.data['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
