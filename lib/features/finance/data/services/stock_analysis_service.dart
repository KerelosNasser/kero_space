import 'package:flutter/foundation.dart';

/// Pure-data result from a stock analysis computation.
class StockAnalysisResult {
  final double sma;
  final double monthlyDiff;
  final String sentiment;

  const StockAnalysisResult({
    required this.sma,
    required this.monthlyDiff,
    required this.sentiment,
  });
}

/// Extracts SMA, monthly change %, and sentiment from price history.
///
/// The heavy computation runs on a background isolate via [compute].
class StockAnalysisService {
  /// Runs analysis in a background isolate.
  static Future<StockAnalysisResult> analyze({
    required List<double> priceHistory,
    required double currentPrice,
    required double changeAmount,
    required double changePercentage,
  }) {
    return compute(_runAnalysis, _AnalysisInput(
      priceHistory: priceHistory,
      currentPrice: currentPrice,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
    ));
  }

  /// Synchronous variant for callers that already hold the result.
  static StockAnalysisResult analyzeSync({
    required List<double> priceHistory,
    required double currentPrice,
    required double changeAmount,
    required double changePercentage,
  }) {
    return _runAnalysis(_AnalysisInput(
      priceHistory: priceHistory,
      currentPrice: currentPrice,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
    ));
  }
}

class _AnalysisInput {
  final List<double> priceHistory;
  final double currentPrice;
  final double changeAmount;
  final double changePercentage;

  _AnalysisInput({
    required this.priceHistory,
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercentage,
  });
}

/// Top-level function for [compute] (must not capture anything).
StockAnalysisResult _runAnalysis(_AnalysisInput input) {
  final priceHistory = input.priceHistory;
  final currentPrice = input.currentPrice;
  final changeAmount = input.changeAmount;
  final changePercentage = input.changePercentage;

  // 7-day Simple Moving Average
  double sma = currentPrice;
  if (priceHistory.length >= 3) {
    final samples = priceHistory.take(7).toList();
    sma = samples.reduce((a, b) => a + b) / samples.length;
  }

  // Monthly change estimation
  double monthlyDiff;
  if (priceHistory.length >= 5) {
    final oldPrice = priceHistory.first;
    monthlyDiff = oldPrice > 0
        ? ((currentPrice - oldPrice) / oldPrice) * 100
        : 0.0;
  } else {
    monthlyDiff = changePercentage;
  }

  // Sentiment indicator
  String sentiment;
  if (priceHistory.length >= 3) {
    if (changeAmount > 0 && currentPrice > sma) {
      sentiment = 'Strong Bullish';
    } else if (changeAmount > 0 && currentPrice <= sma) {
      sentiment = 'Weak Bullish';
    } else if (changeAmount < 0 && currentPrice < sma) {
      sentiment = 'Strong Bearish';
    } else if (changeAmount < 0 && currentPrice >= sma) {
      sentiment = 'Weak Bearish';
    } else {
      sentiment = 'Neutral';
    }
  } else {
    sentiment = changeAmount >= 0 ? 'Bullish' : 'Bearish';
  }

  return StockAnalysisResult(sma: sma, monthlyDiff: monthlyDiff, sentiment: sentiment);
}
