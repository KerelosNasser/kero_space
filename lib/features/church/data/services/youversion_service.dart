import 'package:dio/dio.dart';
import '../models/coptic_day_info.dart';

class YouVersionService {
  final Dio _dio;
  final String? _apiKey;

  YouVersionService({required Dio dio, String? apiKey})
      : _dio = dio,
        _apiKey = apiKey;

  static const _baseUrl = 'https://api.youversion.com';

  /// Returns a URL to open a passage in the YouVersion Bible app.
  String getPassageUrl(ScriptureReference ref) {
    final encoded = Uri.encodeComponent(ref.displayName);
    return 'https://www.bible.com/bible/1/$encoded';
  }

  /// Fetches passage text from YouVersion API.
  /// Returns null if API key is not configured or request fails.
  Future<String?> getPassageText(ScriptureReference ref) async {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    try {
      final response = await _dio.get(
        '$_baseUrl/bible/passage',
        queryParameters: {
          'q': ref.displayName,
          'version': '1', // NIV
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_apiKey'},
        ),
      );
      return response.data['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
