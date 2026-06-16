import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:kero_space/features/finance/data/models/finance_collections.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:isar/isar.dart';
import 'package:injectable/injectable.dart';

@pragma('vm:entry-point')
void notificationCallback(NotificationEvent event) {
  final SendPort? send = IsolateNameServer.lookupPortByName('notification_listener_isolate');
  if (send != null) {
    send.send(event);
  }
}

@pragma('vm:entry-point')
@lazySingleton
class NotificationParserService {
  static const String _isolateName = 'notification_listener_isolate';
  ReceivePort? _port;
  Isar? _isarInstance;

  Future<void> initialize(Isar isar) async {
    _isarInstance = isar;
    _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port!.sendPort, _isolateName);
    
    _port!.listen((message) {
      if (message is NotificationEvent) {
        _handleNotification(message);
      }
    });

    try {
      await NotificationsListener.initialize(callbackHandle: notificationCallback);
    } catch (e) {
      // Ignore platform channel exceptions in tests/unsupported environments
    }
  }

  void _handleNotification(NotificationEvent event) {
    final String content = event.text ?? '';
    final String title = event.title ?? '';
    final String package = event.packageName ?? '';
    
    final fullText = "$title $content $package";

    // Intercept Thndr notifications
    if (package.contains('thndr') || 
        title.toLowerCase().contains('thndr') || 
        content.toLowerCase().contains('thndr')) {
      _handleThndrNotification(fullText);
      return;
    }

    final Transaction? parsedTx = parseText(fullText);

    if (parsedTx != null && _isarInstance != null) {
      _isarInstance!.writeTxnSync(() {
        _isarInstance!.transactions.putSync(parsedTx);
        
        // Auto-update matched MoneySource balance if it exists
        if (parsedTx.sourceName != null) {
          final source = _isarInstance!.moneySources.where().nameEqualTo(parsedTx.sourceName!).findFirstSync();
          if (source != null) {
            if (parsedTx.type == 'INCOME') {
              source.balance += parsedTx.amount;
            } else {
              source.balance -= parsedTx.amount;
            }
            _isarInstance!.moneySources.putSync(source);
          }
        }
      });
    }
  }

  void handleNotificationForTesting(NotificationEvent event) {
    _handleNotification(event);
  }

  void _handleThndrNotification(String text) {
    // Single regex for BUY (English & Arabic)
    final buyMatch = RegExp(
      r'(?:شراء|buy)\s+(\d+)\s+(?:سهم|أسهم|shares?)\s+(?:من|في|of)?\s*([a-zA-Z0-9]+)\s+(?:بسعر|at)\s+(?:EGP|LE|USD|جنيه)?\s*([\d\.,]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (buyMatch != null) {
      final int qty = int.parse(buyMatch.group(1)!);
      final String ticker = buyMatch.group(2)!.toUpperCase();
      final double price = double.parse(buyMatch.group(3)!.replaceAll(',', ''));
      _executeStockTransaction(ticker, qty, price, isBuy: true);
      return;
    }

    // Single regex for SELL (English & Arabic)
    final sellMatch = RegExp(
      r'(?:بيع|sell)\s+(\d+)\s+(?:سهم|أسهم|shares?)\s+(?:من|في|of)?\s*([a-zA-Z0-9]+)\s+(?:بسعر|at)\s+(?:EGP|LE|USD|جنيه)?\s*([\d\.,]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (sellMatch != null) {
      final int qty = int.parse(sellMatch.group(1)!);
      final String ticker = sellMatch.group(2)!.toUpperCase();
      final double price = double.parse(sellMatch.group(3)!.replaceAll(',', ''));
      _executeStockTransaction(ticker, qty, price, isBuy: false);
      return;
    }
  }

  void _executeStockTransaction(String ticker, int qty, double price, {required bool isBuy}) {
    if (_isarInstance == null) return;

    _isarInstance!.writeTxnSync(() {
      // 1. Create investment transaction
      final tx = Transaction()
        ..amount = qty * price
        ..type = isBuy ? 'EXPENSE' : 'INCOME'
        ..category = 'Investment'
        ..vendor = 'Thndr'
        ..sourceName = 'Thndr Wallet'
        ..date = DateTime.now()
        ..isAutoParsed = true
        ..memo = '${isBuy ? 'Bought' : 'Sold'} $qty shares of $ticker at $price EGP';

      _isarInstance!.transactions.putSync(tx);

      // Update Thndr Wallet balance if it exists
      final source = _isarInstance!.moneySources.where().nameEqualTo('Thndr Wallet').findFirstSync();
      if (source != null) {
        if (isBuy) {
          source.balance -= tx.amount;
        } else {
          source.balance += tx.amount;
        }
        _isarInstance!.moneySources.putSync(source);
      }

      // 2. Update holdings
      final holding = _isarInstance!.eGXHoldings.where().tickerEqualTo(ticker).findFirstSync();
      if (isBuy) {
        if (holding != null) {
          final double totalCost = (holding.quantity * holding.averageCost) + (qty * price);
          holding.quantity += qty;
          holding.averageCost = holding.quantity > 0 ? totalCost / holding.quantity : 0.0;
          holding.purchaseDate = DateTime.now();
          _isarInstance!.eGXHoldings.putSync(holding);
        } else {
          final newHolding = EGXHolding()
            ..ticker = ticker
            ..quantity = qty.toDouble()
            ..averageCost = price
            ..purchaseDate = DateTime.now();
          _isarInstance!.eGXHoldings.putSync(newHolding);
        }
      } else {
        if (holding != null) {
          holding.quantity -= qty;
          holding.purchaseDate = DateTime.now();
          if (holding.quantity <= 0) {
            _isarInstance!.eGXHoldings.deleteSync(holding.id);
          } else {
            _isarInstance!.eGXHoldings.putSync(holding);
          }
        }
      }
    });
  }

  Transaction? parseText(String content) {
    // 1. Vodafone Cash
    final vfReceiveMatch = RegExp(r'received\s+([\d,\.]+)\s*EGP\s+from\s+([\d\w]+)', caseSensitive: false).firstMatch(content);
    if (vfReceiveMatch != null) {
      return Transaction()
        ..amount = double.parse(vfReceiveMatch.group(1)!.replaceAll(',', ''))
        ..vendor = vfReceiveMatch.group(2)
        ..type = 'INCOME'
        ..category = _autoCategorize(vfReceiveMatch.group(2)!)
        ..sourceName = 'Vodafone Cash'
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
        ..sourceName = 'Vodafone Cash'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 2. QNB
    final qnbMatch = RegExp(r'purchase\s+transaction\s+done\s+on\s+card\s+\d+\s+with\s+amount\s+EGP\s+([\d,\.]+)\s+at\s+(.*?)(?=\s+on|\.|$)', caseSensitive: false).firstMatch(content);
    if (qnbMatch != null) {
      return Transaction()
        ..amount = double.parse(qnbMatch.group(1)!.replaceAll(',', ''))
        ..vendor = qnbMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(qnbMatch.group(2)!)
        ..sourceName = 'QNB'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 3. NBE
    final nbeMatch = RegExp(r'purchase\s+transaction\s+of\s+EGP\s+([\d,\.]+)\s+from\s+(.*?)\s+using\s+card', caseSensitive: false).firstMatch(content);
    if (nbeMatch != null) {
      return Transaction()
        ..amount = double.parse(nbeMatch.group(1)!.replaceAll(',', ''))
        ..vendor = nbeMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(nbeMatch.group(2)!)
        ..sourceName = 'NBE'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 4. Bybit Card
    final bybitMatch = RegExp(r'Bybit\s+Card:\s+Transaction\s+of\s+([\d,\.]+)\s+(?:USD|EUR|EGP)\s+successful\s+at\s+(.*?)(?=\.|$)', caseSensitive: false).firstMatch(content);
    if (bybitMatch != null) {
      return Transaction()
        ..amount = double.parse(bybitMatch.group(1)!.replaceAll(',', ''))
        ..vendor = bybitMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(bybitMatch.group(2)!)
        ..sourceName = 'Bybit'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    // 5. Instapay
    final instapayMatch = RegExp(r'successfully\s+sent\s+(?:EGP|LE)\s*([\d,\.]+)\s+to\s+(.*?)(?=\s+via|\.|$)', caseSensitive: false).firstMatch(content);
    if (instapayMatch != null) {
      return Transaction()
        ..amount = double.parse(instapayMatch.group(1)!.replaceAll(',', ''))
        ..vendor = instapayMatch.group(2)
        ..type = 'EXPENSE'
        ..category = _autoCategorize(instapayMatch.group(2)!)
        ..sourceName = 'Instapay'
        ..date = DateTime.now()
        ..isAutoParsed = true;
    }

    return null;
  }

  String _autoCategorize(String vendor) {
    final v = vendor.toLowerCase();
    if (v.contains('uber') || v.contains('indrive') || v.contains('careem')) return 'Transport';
    if (v.contains('vodafone') || v.contains('we') || v.contains('orange') || v.contains('etisalat')) return 'Bills & Telecom';
    if (v.contains('mcdonald') || v.contains('kfc') || v.contains('restaurant')) return 'Dining';
    if (v.contains('carrefour') || v.contains('seoudi') || v.contains('spinneys')) return 'Groceries';
    return 'Uncategorized';
  }
}
