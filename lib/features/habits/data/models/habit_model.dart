enum HabitCategory { detox, health, mind, focus }

class Habit {
  final String id;
  final String title;
  final String description;
  final HabitCategory category;
  final int streakCount;
  final int bestStreak;
  final Set<String> completedDates; // Format: 'YYYY-MM-DD'
  final int colorValue;
  final String iconCode;

  const Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.category = HabitCategory.detox,
    this.streakCount = 0,
    this.bestStreak = 0,
    this.completedDates = const {},
    this.colorValue = 0xFF4CAF50,
    this.iconCode = 'eco',
  });

  static String formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(formatDateKey(date));
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  static int calculateStreak(Set<String> completedDates, DateTime referenceDate) {
    int streak = 0;
    DateTime checkDate = referenceDate;

    // If not completed today, check if completed yesterday to preserve active streak
    if (!completedDates.contains(formatDateKey(checkDate))) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(formatDateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    HabitCategory? category,
    int? streakCount,
    int? bestStreak,
    Set<String>? completedDates,
    int? colorValue,
    String? iconCode,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      streakCount: streakCount ?? this.streakCount,
      bestStreak: bestStreak ?? this.bestStreak,
      completedDates: completedDates ?? this.completedDates,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'streakCount': streakCount,
    'bestStreak': bestStreak,
    'completedDates': completedDates.toList(),
    'colorValue': colorValue,
    'iconCode': iconCode,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    title: json['title'] as String,
    description: (json['description'] as String?) ?? '',
    category: HabitCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => HabitCategory.detox,
    ),
    streakCount: (json['streakCount'] as int?) ?? 0,
    bestStreak: (json['bestStreak'] as int?) ?? 0,
    completedDates: ((json['completedDates'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toSet(),
    colorValue: (json['colorValue'] as int?) ?? 0xFF4CAF50,
    iconCode: (json['iconCode'] as String?) ?? 'eco',
  );
}
