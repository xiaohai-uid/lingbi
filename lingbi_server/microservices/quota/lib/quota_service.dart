import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Token Bucket algorithm implementation for quota management.
///
/// The bucket starts full ([dailyLimit] tokens). Tokens are consumed on each
/// request. Tokens are refilled continuously based on [refillRate] tokens per
/// [refillIntervalMs] milliseconds, up to [dailyLimit].
class QuotaService {
  final int dailyLimit;
  final int refillRate;
  final int refillIntervalMs;
  final String storagePath;
  late File _storageFile;

  // Token Bucket state
  int _tokens = 0;
  DateTime _lastRefill = DateTime.now();

  QuotaService({
    required this.dailyLimit,
    this.refillRate = 1,
    this.refillIntervalMs = 60000, // default: 1 token per minute
    required this.storagePath,
  }) {
    _storageFile = File(storagePath);
    _loadState();
  }

  void _loadState() {
    try {
      if (_storageFile.existsSync()) {
        final content = _storageFile.readAsStringSync();
        final data = json.decode(content) as Map<String, dynamic>;
        _tokens = data['tokens'] ?? dailyLimit;
        _lastRefill = DateTime.parse(
          data['lastRefill'] ?? DateTime.now().toIso8601String(),
        );
      } else {
        _tokens = dailyLimit;
        _lastRefill = DateTime.now();
      }
    } catch (e) {
      print('Error loading state: $e');
      _tokens = dailyLimit;
      _lastRefill = DateTime.now();
    }
  }

  void _saveState() {
    try {
      final data = {
        'tokens': _tokens,
        'lastRefill': _lastRefill.toIso8601String(),
      };
      _storageFile.writeAsStringSync(json.encode(data));
    } catch (e) {
      print('Error saving state: $e');
    }
  }

  /// Refill tokens based on elapsed time (Token Bucket algorithm).
  void _refill() {
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastRefill).inMilliseconds;

    if (elapsedMs <= 0) return;

    // Calculate tokens to add: for each full refillIntervalMs, add refillRate tokens
    final intervals = elapsedMs ~/ refillIntervalMs;
    if (intervals > 0) {
      final tokensToAdd = intervals * refillRate;
      _tokens = min(dailyLimit, _tokens + tokensToAdd);
      _lastRefill = now;
      _saveState();
    }
  }

  /// Try to consume one token.
  /// Returns: {success: bool, message: String, remaining: int}
  Map<String, dynamic> consume() {
    _refill();

    if (_tokens > 0) {
      _tokens--;
      _saveState();
      return {
        'success': true,
        'message': 'Token consumed successfully',
        'remaining': _tokens,
      };
    } else {
      return {
        'success': false,
        'message': 'Rate limit exceeded — no tokens available',
        'remaining': 0,
      };
    }
  }

  /// Try to consume [count] tokens at once.
  /// Returns: {success: bool, message: String, remaining: int, consumed: int}
  Map<String, dynamic> consumeMany(int count) {
    _refill();

    final actual = count > _tokens ? _tokens : count;
    if (actual > 0) {
      _tokens -= actual;
      _saveState();
      return {
        'success': actual == count,
        'message': actual == count
            ? 'Consumed $count tokens'
            : 'Only consumed $actual of $count tokens',
        'remaining': _tokens,
        'consumed': actual,
      };
    } else {
      return {
        'success': false,
        'message': 'Rate limit exceeded — no tokens available',
        'remaining': 0,
        'consumed': 0,
      };
    }
  }

  /// Get current status of the token bucket.
  Map<String, dynamic> getStatus() {
    _refill();
    final utilization = dailyLimit > 0
        ? ((dailyLimit - _tokens) / dailyLimit * 100).toStringAsFixed(1)
        : '0.0';
    return {
      'remaining': _tokens,
      'limit': dailyLimit,
      'lastRefill': _lastRefill.toIso8601String(),
      'utilization': '$utilization%',
      'refillRate': refillRate,
      'refillIntervalMs': refillIntervalMs,
    };
  }

  /// Reset quota to full capacity.
  Map<String, dynamic> reset() {
    _tokens = dailyLimit;
    _lastRefill = DateTime.now();
    _saveState();
    return {
      'success': true,
      'message': 'Quota reset successfully',
      'remaining': _tokens,
      'limit': dailyLimit,
    };
  }
}
