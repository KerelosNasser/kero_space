import 'dart:convert';

class BlacklistRule {
  final String packageName;
  final String? subAppTarget;
  final List<TimeWindow> allowedWindows;
  final int dailyQuotaMinutes;
  final int decisionBreakSeconds;
  
  final int? sessionLimitMinutes;
  final int? cooldownMinutes;
  final bool strictMode;

  const BlacklistRule({
    required this.packageName,
    this.subAppTarget,
    this.allowedWindows = const [],
    this.dailyQuotaMinutes = 0,
    this.decisionBreakSeconds = 30,
    this.sessionLimitMinutes,
    this.cooldownMinutes,
    this.strictMode = true,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    if (subAppTarget != null) 'subAppTarget': subAppTarget,
    'allowedWindows': allowedWindows.map((w) => w.toJson()).toList(),
    'dailyQuotaMinutes': dailyQuotaMinutes,
    'decisionBreakSeconds': decisionBreakSeconds,
    if (sessionLimitMinutes != null) 'sessionLimitMinutes': sessionLimitMinutes,
    if (cooldownMinutes != null) 'cooldownMinutes': cooldownMinutes,
    'strictMode': strictMode,
  };

  factory BlacklistRule.fromJson(Map<String, dynamic> json) => BlacklistRule(
    packageName: json['packageName'] as String,
    subAppTarget: json['subAppTarget'] as String?,
    allowedWindows: ((json['allowedWindows'] as List<dynamic>?) ?? [])
        .map((e) => TimeWindow.fromJson(e as Map<String, dynamic>))
        .toList(),
    dailyQuotaMinutes: (json['dailyQuotaMinutes'] as int?) ?? 0,
    decisionBreakSeconds: (json['decisionBreakSeconds'] as int?) ?? 30,
    sessionLimitMinutes: json['sessionLimitMinutes'] as int?,
    cooldownMinutes: json['cooldownMinutes'] as int?,
    strictMode: (json['strictMode'] as bool?) ?? true,
  );

  static List<BlacklistRule> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => BlacklistRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<BlacklistRule> rules) =>
      jsonEncode(rules.map((r) => r.toJson()).toList());
}

class TimeWindow {
  final int startHour;
  final int endHour;

  const TimeWindow({required this.startHour, required this.endHour});

  Map<String, dynamic> toJson() => {'startHour': startHour, 'endHour': endHour};
  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      TimeWindow(startHour: json['startHour'] as int, endHour: json['endHour'] as int);
}
