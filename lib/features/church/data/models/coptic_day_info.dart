enum FastingStatus { none, strict, fishAllowed, vegan }

class ScriptureReference {
  final String book;
  final String chapter;
  final String verses;
  final String displayName;

  const ScriptureReference({
    required this.book,
    required this.chapter,
    required this.verses,
    required this.displayName,
  });
}

class UpcomingFeast {
  final String name;
  final DateTime date;
  final int daysRemaining;
  final bool isMajor;

  const UpcomingFeast({
    required this.name,
    required this.date,
    required this.daysRemaining,
    this.isMajor = false,
  });
}

class CopticDayInfo {
  final int copticYear;
  final int copticMonth;
  final int copticDay;
  final String monthName;
  final String? feastName;
  final String? feastDescription;
  final FastingStatus fastStatus;
  final String? seasonName;
  final List<ScriptureReference> readings;
  final List<UpcomingFeast> upcomingFeasts;

  const CopticDayInfo({
    required this.copticYear,
    required this.copticMonth,
    required this.copticDay,
    required this.monthName,
    this.feastName,
    this.feastDescription,
    this.fastStatus = FastingStatus.none,
    this.seasonName,
    this.readings = const [],
    this.upcomingFeasts = const [],
  });
}
