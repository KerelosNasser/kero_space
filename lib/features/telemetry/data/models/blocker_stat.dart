class BlockerStat {
  final String packageName;
  final int blockedAttempts;
  final int grantedOverrides;
  final DateTime date;

  const BlockerStat({
    required this.packageName,
    required this.blockedAttempts,
    required this.grantedOverrides,
    required this.date,
  });

  double get resistanceRate =>
      blockedAttempts + grantedOverrides == 0
          ? 0
          : blockedAttempts / (blockedAttempts + grantedOverrides);

  String get resistanceLabel =>
      '${(resistanceRate * 100).toStringAsFixed(0)}% — '
      'You resisted the urge ${(resistanceRate * 100).toStringAsFixed(0)}% of the time';
}
