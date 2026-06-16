import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class EGXScraperService {
  final Dio _dio;

  EGXScraperService({Dio? dio}) : _dio = dio ?? Dio();

  /// Scrapes the latest price for an EGX ticker from Mubasher.
  /// Example: 'COMI'
  Future<double?> fetchPrice(String ticker) async {
    // Basic Mubasher English URL structure for EGX stocks
    final url = 'https://english.mubasher.info/markets/EGX/stocks/${ticker.toUpperCase()}';
    
    try {
      final response = await _dio.get(url, options: Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
      ));
      
      if (response.statusCode == 200) {
        var document = parse(response.data);
        var priceElement = document.querySelector('.market-summary__last-price') ??
                           document.querySelector('.market-summary__price');
        
        if (priceElement != null) {
          String priceText = priceElement.text.replaceAll(RegExp(r'[^0-9.]'), '');
          return double.tryParse(priceText);
        }
      }
    } catch (e) {
      debugPrint('Error fetching price for $ticker: $e');
    }
    return null;
  }
}
