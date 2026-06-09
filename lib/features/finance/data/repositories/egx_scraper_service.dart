import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;

class EGXScraperService {
  final Dio _dio;

  EGXScraperService({Dio? dio}) : _dio = dio ?? Dio();

  /// Scrapes the latest price for an EGX ticker from Mubasher.
  /// Example: 'COMI'
  Future<double?> fetchPrice(String ticker) async {
    // Basic Mubasher English URL structure for EGX stocks
    final url = 'https://english.mubasher.info/markets/EGX/stocks/${ticker.toUpperCase()}';
    
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = parse(response.data);
        
        // Find the span containing the price
        final priceSpans = document.getElementsByClassName('market-summary__last-price');
        
        if (priceSpans.isNotEmpty) {
          final priceText = priceSpans.first.text.trim().replaceAll(',', '');
          return double.tryParse(priceText);
        }
      }
    } catch (e) {
      print('Error scraping $ticker: $e');
    }
    return null;
  }
}
