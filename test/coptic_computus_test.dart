import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/core/utils/coptic_computus.dart';

void main() {
  group('Coptic Computus', () {
    test('Calculates Pascha Correctly', () {
      expect(CopticComputus.getGregorianPascha(2024), DateTime(2024, 5, 5));
      expect(CopticComputus.getGregorianPascha(2025), DateTime(2025, 4, 20));
      expect(CopticComputus.getGregorianPascha(2026), DateTime(2026, 4, 12));
      expect(CopticComputus.getGregorianPascha(2027), DateTime(2027, 5, 2));
    });

    test('Identifies Great Lent', () {
      final fast = CopticComputus.getFastType(DateTime(2024, 4, 1));
      expect(fast, FastType.greatLent);
      expect(CopticComputus.isVeganStrict(fast), isTrue);
    });

    test('Identifies Advent Fast End Date (Jan 7)', () {
      // Jan 6 is fasting
      expect(CopticComputus.getFastType(DateTime(2025, 1, 6)), FastType.adventFast);
      
      // Jan 7 is not fasting (Feast)
      expect(CopticComputus.getFastType(DateTime(2025, 1, 7)), FastType.none);
    });

    test('Identifies Pentecost / Holy 50 Days', () {
      // May 10, 2024 is Friday after Pascha (May 5, 2024)
      final may10 = DateTime(2024, 5, 10);
      expect(may10.weekday, DateTime.friday);
      
      // Should be NO fast because it's during Holy 50 Days
      expect(CopticComputus.getFastType(may10), FastType.none);
    });
  });
}
