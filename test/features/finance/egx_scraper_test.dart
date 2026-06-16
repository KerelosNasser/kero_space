import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/repositories/egx_scraper_service.dart';

void main() {
  test('EGXScraperService returns EGXScrapeResult', () async {
    final scraper = EGXScraperService();
    final result = await scraper.fetchPrice('COMI');
    if (result != null) {
      expect(result.price, isPositive);
      expect(result.changePercentage, isNotNull);
      expect(result.changeAmount, isNotNull);
    }
  });
}
