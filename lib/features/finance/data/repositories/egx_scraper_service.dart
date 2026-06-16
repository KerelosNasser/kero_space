import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';

class EGXScrapeResult {
  final double price;
  final double changeAmount;
  final double changePercentage;

  EGXScrapeResult({
    required this.price,
    required this.changeAmount,
    required this.changePercentage,
  });
}

class EGXScraperService {
  final Dio _dio;

  EGXScraperService({Dio? dio}) : _dio = dio ?? Dio();

  /// Scrapes the latest price and daily changes for an EGX ticker from Mubasher.
  /// Example: 'COMI'
  Future<EGXScrapeResult?> fetchPrice(String ticker) async {
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
        var changeElement = document.querySelector('.market-summary__change');
        var pctElement = document.querySelector('.market-summary__change-percentage');
        
        if (priceElement != null) {
          String priceText = priceElement.text.replaceAll(RegExp(r'[^0-9.-]'), '');
          String changeText = changeElement?.text.replaceAll(RegExp(r'[^0-9.-]'), '') ?? '0.0';
          String pctText = pctElement?.text.replaceAll(RegExp(r'[^0-9.-]'), '') ?? '0.0';

          return EGXScrapeResult(
            price: double.tryParse(priceText) ?? 0.0,
            changeAmount: double.tryParse(changeText) ?? 0.0,
            changePercentage: double.tryParse(pctText) ?? 0.0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching price for $ticker: $e');
    }
    return null;
  }
}
