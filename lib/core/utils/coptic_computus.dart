enum FastType {
  none,
  greatLent,
  jonahsFast,
  apostlesFast,
  adventFast,
  wednesdayFriday,
  paramoun, // Eve of Nativity/Theophany
}

class CopticFastCycle {
  final DateTime pascha;
  final DateTime greatLentStart;
  final DateTime jonahsFastStart;
  final DateTime pentecost;
  final DateTime apostlesFastStart;

  CopticFastCycle(int year) : this.fromPascha(CopticComputus.getGregorianPascha(year));

  CopticFastCycle.fromPascha(this.pascha)
      : greatLentStart = pascha.subtract(const Duration(days: 55)),
        jonahsFastStart = pascha.subtract(const Duration(days: 69)),
        pentecost = pascha.add(const Duration(days: 49)), // 50th day inclusive is +49 days
        apostlesFastStart = pascha.add(const Duration(days: 50)); // Day after Pentecost
}

class CopticComputus {
  /// Calculates the Orthodox Pascha (Easter) using the Meeus/Gauss Julian algorithm
  /// and applies the Gregorian offset for the 20th/21st centuries.
  static DateTime getGregorianPascha(int year) {
    int a = year % 19;
    int i = (a * 19 + 15) % 30;
    int j = (year + (year ~/ 4) + i + 2) % 7;
    int l = i - j;
    int month = 3 + ((l + 40) ~/ 44);
    int day = l + 28 - (31 * (month ~/ 4));
    
    // Julian to Gregorian offset (valid from 1900 to 2099)
    return DateTime(year, month, day).add(const Duration(days: 13));
  }

  /// Determines the fasting status and strictness of a given date.
  static FastType getFastType(DateTime date) {
    final year = date.year;
    final cycle = CopticFastCycle(year);

    // Normalize date to ignore time
    final target = DateTime(date.year, date.month, date.day);

    // Check Jonah's Fast (3 days)
    if (!target.isBefore(cycle.jonahsFastStart) && target.isBefore(cycle.jonahsFastStart.add(const Duration(days: 3)))) {
      return FastType.jonahsFast;
    }

    // Check Great Lent (55 days ending on Pascha eve)
    if (!target.isBefore(cycle.greatLentStart) && target.isBefore(cycle.pascha)) {
      return FastType.greatLent;
    }

    // Check Holy 50 Days (no fasting)
    if (!target.isBefore(cycle.pascha) && target.isBefore(cycle.pentecost.add(const Duration(days: 1)))) {
      return FastType.none;
    }

    // Check Apostles' Fast (Pentecost + 1 until July 12)
    final apostlesEnd = DateTime(year, 7, 12);
    if (!target.isBefore(cycle.apostlesFastStart) && target.isBefore(apostlesEnd)) {
      return FastType.apostlesFast;
    }

    // Check Advent (Nativity) Fast (Nov 25 to Jan 7)
    // Runs from Nov 25 of current year to Jan 7 of next year
    // If target is in Jan 1-6, check previous year's Advent start
    final adventStartThisYear = DateTime(year, 11, 25);
    final adventEndThisYear = DateTime(year + 1, 1, 7);
    
    final adventStartPrevYear = DateTime(year - 1, 11, 25);
    final adventEndPrevYear = DateTime(year, 1, 7);

    if ((!target.isBefore(adventStartThisYear) && target.isBefore(adventEndThisYear)) ||
        (!target.isBefore(adventStartPrevYear) && target.isBefore(adventEndPrevYear))) {
      return FastType.adventFast;
    }

    // Check Wednesday and Friday
    if (target.weekday == DateTime.wednesday || target.weekday == DateTime.friday) {
      // Feast of Nativity (Jan 7) and Theophany (Jan 19) are never fasting days
      if (target.month == 1 && (target.day == 7 || target.day == 19)) return FastType.none;
      return FastType.wednesdayFriday;
    }

    return FastType.none;
  }

  static bool isVeganStrict(FastType type) {
    // True if absolutely no fish allowed (e.g. Wednesday/Friday, Great Lent, Jonah's Fast)
    // False if fish is permitted (Advent, Apostles)
    return type == FastType.greatLent || 
           type == FastType.jonahsFast || 
           type == FastType.wednesdayFriday || 
           type == FastType.paramoun;
  }
}
