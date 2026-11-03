import 'package:shared_preferences/shared_preferences.dart';

class ReadingGoalSnapshot {
  final int targetPages;
  final int completedPages;
  final String date;
  const ReadingGoalSnapshot({required this.targetPages, required this.completedPages, required this.date});
  double get progress => targetPages <= 0 ? 0 : (completedPages / targetPages).clamp(0.0, 1.0).toDouble();
  bool get isComplete => completedPages >= targetPages;
}

class ReadingGoalService {
  static const _targetKey = 'reading_goal_target_pages';
  static const _completedKey = 'reading_goal_completed_pages';
  static const _dateKey = 'reading_goal_date';
  String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<ReadingGoalSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _today();
    final savedDate = prefs.getString(_dateKey);
    if (savedDate != today) {
      await prefs.setString(_dateKey, today);
      await prefs.setInt(_completedKey, 0);
    }
    return ReadingGoalSnapshot(
      targetPages: (prefs.getInt(_targetKey) ?? 4).clamp(1, 30).toInt(),
      completedPages: (prefs.getInt(_completedKey) ?? 0).clamp(0, 604).toInt(),
      date: today,
    );
  }

  Future<ReadingGoalSnapshot> setTarget(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, pages.clamp(1, 30).toInt());
    return load();
  }

  Future<ReadingGoalSnapshot> addPages(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    await prefs.setInt(_completedKey, (current.completedPages + pages).clamp(0, 604).toInt());
    return load();
  }

  Future<ReadingGoalSnapshot> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_completedKey, 0);
    return load();
  }
}
