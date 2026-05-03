import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/database_service.dart';

class FastingSummary {
  final int fasted;
  final int debt;
  final int remaining;

  const FastingSummary({
    required this.fasted,
    required this.debt,
    required this.remaining,
  });

  factory FastingSummary.initial() =>
      const FastingSummary(fasted: 0, debt: 0, remaining: 30);

  FastingSummary copyWith({int? fasted, int? debt, int? remaining}) {
    return FastingSummary(
      fasted: fasted ?? this.fasted,
      debt: debt ?? this.debt,
      remaining: remaining ?? this.remaining,
    );
  }
}

class FastingState {
  final Map<String, int> logs; // date ISO string -> status(0,1,2)
  final FastingSummary summary;

  const FastingState({required this.logs, required this.summary});

  factory FastingState.initial() =>
      FastingState(logs: {}, summary: FastingSummary.initial());
}

class FastingNotifier extends StateNotifier<FastingState> {
  final DatabaseService _dbService;

  FastingNotifier(this._dbService) : super(FastingState.initial()) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final rawLogs = await _dbService.fetchAllLogs();
    final Map<String, int> logs = {};
    int fasted = 0;
    int debt = 0;

    for (final row in rawLogs) {
      final date = row['date'] as String;
      final status = row['status'] as int;
      logs[date] = status;
      if (status == 1) fasted++;
      if (status == 2) debt++;
    }

    final totalRamadanDays = 30;
    int remaining = totalRamadanDays - (fasted + debt);
    if (remaining < 0) remaining = 0;

    state = FastingState(
      logs: logs,
      summary: FastingSummary(fasted: fasted, debt: debt, remaining: remaining),
    );
  }

  Future<void> setStatusForToday(int status) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    await _dbService.insertOrUpdateLog(dateStr, status);
    await _loadLogs(); // Refresh state
  }

  int getTodayStatus() {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return state.logs[dateStr] ?? 0;
  }
}

final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((
  ref,
) {
  return FastingNotifier(DatabaseService.instance);
});
