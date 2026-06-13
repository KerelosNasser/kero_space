import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/blacklist_rule.dart';

const _kBlacklistKey = 'kero_blacklist_rules_v1';

class BlacklistRepository {
  final FlutterSecureStorage _storage;
  BlacklistRepository(this._storage);

  Future<List<BlacklistRule>> getRules() async {
    final raw = await _storage.read(key: _kBlacklistKey);
    if (raw == null || raw.isEmpty) return [];
    return BlacklistRule.listFromJson(raw);
  }

  Future<void> saveRules(List<BlacklistRule> rules) async {
    await _storage.write(key: _kBlacklistKey, value: BlacklistRule.listToJson(rules));
  }

  Future<void> addRule(BlacklistRule rule) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == rule.packageName);
    rules.add(rule);
    await saveRules(rules);
  }

  Future<void> removeRule(String packageName) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == packageName);
    await saveRules(rules);
  }

  Future<void> updateRule(BlacklistRule updated) async {
    final rules = await getRules();
    final idx = rules.indexWhere((r) => r.packageName == updated.packageName);
    if (idx >= 0) rules[idx] = updated;
    await saveRules(rules);
  }
}
