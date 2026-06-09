import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:isar/isar.dart';

class NotificationParserService {
  static const String _isolateName = 'notification_listener_isolate';
  static ReceivePort? _port;
  static Isar? _isarInstance;

  static Future<void> initialize(Isar isar) async {
    _isarInstance = isar;
    
    // Register port for background isolate communication
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _isolateName);
    
    _port!.listen((message) {
      if (message is NotificationEvent) {
        _handleNotification(message);
      }
    });

    // Start listening
    await NotificationsListener.initialize(callbackHandle: _callback);
  }

  @pragma('vm:entry-point')
  static void _callback(NotificationEvent event) {
    final SendPort? send = IsolateNameServer.lookupPortByName(_isolateName);
    if (send != null) {
      send.send(event);
    }
  }

  static void _handleNotification(NotificationEvent event) {
    final String content = event.text ?? '';
    final String title = event.title ?? '';
    final String package = event.packageName ?? '';
    
    // Only parse if it comes from known financial packages (this can be expanded)
    if (!package.contains('banking') && 
        !package.contains('vodafone') && 
        !package.contains('instapay') &&
        !package.contains('cib')) {
      // For now, let's just run regex against everything if no specific package filtering is preferred
      // but in production filtering by package saves processing.
    }

    final fullText = "$title $content";
    final Transaction? parsedTx = _parseText(fullText);

    if (parsedTx != null && _isarInstance != null) {
      // Save the transaction to DB automatically
      _isarInstance!.writeTxnSync(() {
        _isarInstance!.transactions.putSync(parsedTx);
      });
    }
  }

  static Transaction? _parseText(String content) {
    // 1. Vodafone Cash patterns
    final vfReceiveMatch = RegExp(r'received\s+([\d,\.]+)\s*EGP\s+from\s+([\d\w]+)', caseSensitive: false).firstMatch(content);
    if (vfReceiveMatch != null) {
      return Transaction()
        ..amount = double.parse(vfReceiveMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfReceiveMatch.group(2)
        ..type = 'INCOME'
        ..category = _autoCategorize(vfReceiveMatch.group(2)!)
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }
    
    final vfSendMatch = RegExp(r'(?:transfer|payment)\s+of\s+([\d,\.]+)\s*EGP\s+to\s+(.*?)(?=\s|$)', caseSensitive: false).firstMatch(content);
    if (vfSendMatch != null) {
      return Transaction()
        ..amount = double.parse(vfSendMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfSendMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(vfSendMatch.group(2)!)
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 2. CIB Pattern
    final cibMatch = RegExp(r'purchase\s+of\s+EGP\s+([\d,\.]+)\s+from\s+(.*?)\s+on\s+card', caseSensitive: false).firstMatch(content);
    if (cibMatch != null) {
      return Transaction()
        ..amount = double.parse(cibMatch.group(1)!.replaceAll(',', ''))
        ..vendor = cibMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(cibMatch.group(2)!)
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 3. Instapay pattern
    final instapayMatch = RegExp(r'successfully\s+sent\s+(?:EGP|LE)\s*([\d,\.]+)\s+to\s+(.*?)(?=\s+via|\.|$)', caseSensitive: false).firstMatch(content);
    if (instapayMatch != null) {
      return Transaction()
        ..amount = double.parse(instapayMatch.group(1)!.replaceAll(',', ''))
        ..vendor = instapayMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(instapayMatch.group(2)!)
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    return null;
  }

  static String _autoCategorize(String vendor) {
    final v = vendor.toLowerCase();
    if (v.contains('uber') || v.contains('indrive') || v.contains('careem')) return 'Transport';
    if (v.contains('vodafone') || v.contains('we') || v.contains('orange') || v.contains('etisalat')) return 'Bills & Telecom';
    if (v.contains('mcdonald') || v.contains('kfc') || v.contains('restaurant')) return 'Dining';
    if (v.contains('carrefour') || v.contains('seoudi') || v.contains('spinneys')) return 'Groceries';
    return 'Uncategorized';
  }
}
