import 'dart:convert';
import 'dart:io';

class QuotaService {
  final int dailyLimit;
  final String storagePath;
  late File _storageFile;

  // Token Bucket state
  int _tokens = 0;
  DateTime _lastRefill = DateTime.now();

  QuotaService({required this.dailyLimit, required this.storagePath}) {
    _storageFile = File(storagePath);
    _loadState();
  }

  void _loadState() {
    try {
      if (_storageFile.existsSync()) {
        final content = _storageFile.readAsStringSync();
        final data = json.decode(content) as Map<String, dynamic>;
        _tokens = data['tokens'] ?? dailyLimit;
        _lastRefill = DateTime.parse(data['lastRefill'] ?? DateTime.now().toIso8601String());
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

  // Refill tokens based on time elapsed (daily refill)
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    
    // If a day has passed, reset to full limit
    if (elapsed.inDays >= 1) {
      _tokens = dailyLimit;
      _lastRefill = now;
      _saveState();
    }
  }

  /// Try to consume a token
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
        'message': 'Daily limit reached',
        'remaining': 0,
      };
    }
  }

  /// Reset quota to full limit
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

  /// Get current status
  Map<String, dynamic> getStatus() {
    _refill();
    return {
      'remaining': _tokens,
      'limit': dailyLimit,
      'lastRefill': _lastRefill.toIso8601String(),
      'resetIn': _tokens == 0 ? 'Already at limit' : '${_tokens} tokens available',
    };
  }
}
