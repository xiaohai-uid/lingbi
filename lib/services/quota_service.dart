class QuotaService {
  QuotaService();
  int _dailyUsage = 0;
  final int _dailyLimit = 100;
  DateTime _lastReset = DateTime.now();

  int get dailyUsage => _dailyUsage;
  int get dailyLimit => _dailyLimit;
  int get remaining => _dailyLimit - _dailyUsage;

  bool get canUse => _dailyUsage < _dailyLimit;

  void _checkReset() {
    final now = DateTime.now();
    if (_lastReset.day != now.day) {
      _dailyUsage = 0;
      _lastReset = now;
    }
  }

  bool tryConsume() {
    _checkReset();
    if (_dailyUsage >= _dailyLimit) return false;
    _dailyUsage++;
    return true;
  }

  void reset() {
    _dailyUsage = 0;
    _lastReset = DateTime.now();
  }
}
