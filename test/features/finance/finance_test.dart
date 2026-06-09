import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';

// Dummy regex parser for test-driven development before moving to service
class NotificationParser {
  static Transaction? parse(String content) {
    // Vodafone Cash Pattern: "You have received 500 EGP from 010XXXXX" or "Transfer of 150 EGP to 010XXXXX"
    final vfReceiveMatch = RegExp(r'received\s+([\d,\.]+)\s*EGP\s+from\s+([\d\w]+)', caseSensitive: false).firstMatch(content);
    if (vfReceiveMatch != null) {
      return Transaction()
        ..amount = double.parse(vfReceiveMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfReceiveMatch.group(2)
        ..type = 'INCOME'
        ..category = 'Transfer'
        ..isAutoParsed = true;
    }
    
    final vfSendMatch = RegExp(r'(?:transfer|payment)\s+of\s+([\d,\.]+)\s*EGP\s+to\s+(.*?)(?=\s|$)', caseSensitive: false).firstMatch(content);
    if (vfSendMatch != null) {
      return Transaction()
        ..amount = double.parse(vfSendMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfSendMatch.group(2)
        ..type = 'EXPENSE'
        ..category = 'Uncategorized'
        ..isAutoParsed = true;
    }

    // CIB Pattern: "Purchase of EGP 250.00 from UBER EGYPT on card ending 1234"
    final cibMatch = RegExp(r'purchase\s+of\s+EGP\s+([\d,\.]+)\s+from\s+(.*?)\s+on\s+card', caseSensitive: false).firstMatch(content);
    if (cibMatch != null) {
      return Transaction()
        ..amount = double.parse(cibMatch.group(1)!.replaceAll(',', ''))
        ..vendor = cibMatch.group(2)
        ..type = 'EXPENSE'
        ..category = 'Uncategorized'
        ..isAutoParsed = true;
    }

    // Instapay pattern: "You have successfully sent EGP 1,250.00 to Kerelos Nasser"
    final instapayMatch = RegExp(r'successfully\s+sent\s+(?:EGP|LE)\s*([\d,\.]+)\s+to\s+(.*?)(?=\s+via|\.|$)', caseSensitive: false).firstMatch(content);
    if (instapayMatch != null) {
      return Transaction()
        ..amount = double.parse(instapayMatch.group(1)!.replaceAll(',', ''))
        ..vendor = instapayMatch.group(2)
        ..type = 'EXPENSE'
        ..category = 'Transfer'
        ..isAutoParsed = true;
    }

    return null;
  }
}

void main() {
  group('Finance Models & Notification Parsing TDD', () {
    
    test('Transaction maps fields correctly', () {
      final tx = Transaction()
        ..amount = 150.0
        ..type = 'EXPENSE'
        ..vendor = 'Uber'
        ..category = 'Transport';
      expect(tx.amount, 150.0);
      expect(tx.type, 'EXPENSE');
    });

    test('Regex parser extracts CIB POS expense amount and vendor correctly', () {
      final msg = "Purchase of EGP 250.00 from UBER EGYPT on card ending 1234";
      final tx = NotificationParser.parse(msg);
      expect(tx, isNotNull);
      expect(tx!.amount, 250.0);
      expect(tx.vendor, 'UBER EGYPT');
      expect(tx.type, 'EXPENSE');
    });

    test('Regex parser extracts Vodafone Cash transfer amount correctly', () {
      final msg = "You have received 500 EGP from 01012345678";
      final tx = NotificationParser.parse(msg);
      expect(tx, isNotNull);
      expect(tx!.amount, 500.0);
      expect(tx.vendor, '01012345678');
      expect(tx.type, 'INCOME');
    });

    test('Regex parser extracts Instapay transfer amount correctly', () {
      final msg = "You have successfully sent EGP 1,250.00 to Kerelos Nasser via Instapay.";
      final tx = NotificationParser.parse(msg);
      expect(tx, isNotNull);
      expect(tx!.amount, 1250.0);
      expect(tx.vendor, 'Kerelos Nasser');
      expect(tx.type, 'EXPENSE');
    });

  });
}
