import '../models/coptic_day_info.dart';

class _CopticDateResult {
  final int year;
  final int month;
  final int day;
  final String monthName;
  const _CopticDateResult({
    required this.year,
    required this.month,
    required this.day,
    required this.monthName,
  });
}

class _FeastInfo {
  final String name;
  final String description;
  const _FeastInfo(this.name, this.description);
}

class CopticCalendarService {
  static const List<String> _copticMonths = [
    'Tout',
    'Baba',
    'Hator',
    'Kiahk',
    'Toba',
    'Amshir',
    'Baramhat',
    'Baramouda',
    'Bashans',
    'Paona',
    'Epep',
    'Mesra',
    'Nasie',
  ];

  /// Compute Coptic date from a Gregorian DateTime.
  static _CopticDateResult _toCopticDate(DateTime greg) {
    final int year = greg.year;
    final int month = greg.month;

    // Coptic year starts on 11 Sep (12 Sep after Coptic leap year)
    int copticYear = year - 283;
    if (month < 9) copticYear = year - 284;

    // Days since Coptic New Year (1 Tout = 11 Sep)
    final copticNewYear = DateTime(year, 9, 11);
    final diff = greg.difference(copticNewYear).inDays;

    int copticMonth = 1;
    int copticDay = 1;
    if (diff >= 0) {
      copticDay = diff + 1;
      int daysInMonth = 30;
      while (copticDay > daysInMonth) {
        copticDay -= daysInMonth;
        copticMonth++;
        if (copticMonth == 13) {
          daysInMonth = _isCopticLeapYear(copticYear) ? 6 : 5;
        } else {
          daysInMonth = 30;
        }
      }
    }

    return _CopticDateResult(
      year: copticYear,
      month: copticMonth,
      day: copticDay,
      monthName: _copticMonths[copticMonth - 1],
    );
  }

  static bool _isCopticLeapYear(int copticYear) {
    return (copticYear % 4 == 0) &&
        (copticYear % 100 != 0 || copticYear % 400 == 0);
  }

  static CopticDayInfo computeToday() => computeForDate(DateTime.now());

  static CopticDayInfo computeForDate(DateTime date) {
    final cd = _toCopticDate(date);
    final feast = _getFeastForDate(cd.month, cd.day);
    final fastStatus = _getFastingStatus(date);
    final season = _getSeason(cd.month);
    final readings = _getReadingsForDate(cd.month, cd.day);
    final upcoming = _getUpcomingFeasts(date);

    return CopticDayInfo(
      copticYear: cd.year,
      copticMonth: cd.month,
      copticDay: cd.day,
      monthName: cd.monthName,
      feastName: feast?.name,
      feastDescription: feast?.description,
      fastStatus: fastStatus,
      seasonName: season,
      readings: readings,
      upcomingFeasts: upcoming,
    );
  }

  static _FeastInfo? _getFeastForDate(int month, int day) {
    const feasts = <(int, int), (String, String)>{
      (7, 1): (
        'Feast of the Entry of the Lord into Egypt',
        "Commemorating the Holy Family's flight into Egypt"
      ),
      (7, 21): (
        'Feast of the Transfiguration',
        "The revelation of Christ's divine glory on Mount Tabor"
      ),
      (12, 6): (
        'Feast of the Nativity',
        'The birth of our Lord and Savior Jesus Christ'
      ),
    };
    final f = feasts[(month, day)];
    if (f != null) return _FeastInfo(f.$1, f.$2);
    return null;
  }

  static FastingStatus _getFastingStatus(DateTime greg) {
    final weekday = greg.weekday;
    if (weekday == DateTime.wednesday || weekday == DateTime.friday) {
      return FastingStatus.fishAllowed;
    }
    return FastingStatus.none;
  }

  static String? _getSeason(int copticMonth) {
    if (copticMonth == 4) return 'Kiahk Month (Advent Preparation)';
    if (copticMonth == 12) return 'Nativity Season';
    return null;
  }

  static List<ScriptureReference> _getReadingsForDate(int month, int day) {
    return const [
      ScriptureReference(
        book: 'John',
        chapter: '1',
        verses: '1-17',
        displayName: 'John 1:1-17',
      ),
    ];
  }

  static List<UpcomingFeast> _getUpcomingFeasts(DateTime now) {
    const feasts = <String, (int, int)>{
      'Nativity': (12, 29),
      'Epiphany': (1, 19),
      'Entry of Lord into Egypt': (6, 1),
      'Transfiguration': (8, 19),
    };
    final result = <UpcomingFeast>[];
    for (final entry in feasts.entries) {
      final feastDate =
          DateTime(now.year, entry.value.$1, entry.value.$2);
      final adjusted = feastDate.isBefore(now)
          ? DateTime(now.year + 1, entry.value.$1, entry.value.$2)
          : feastDate;
      final days = adjusted.difference(now).inDays;
      if (days > 0 && days <= 365) {
        result.add(UpcomingFeast(
          name: entry.key,
          date: adjusted,
          daysRemaining: days,
          isMajor: ['Nativity', 'Epiphany'].contains(entry.key),
        ));
      }
    }
    result.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return result.take(5).toList();
  }
}
