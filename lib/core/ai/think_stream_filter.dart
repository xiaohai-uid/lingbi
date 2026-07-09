class ThinkStreamFilter {
  static final _thinkRE = RegExp(r'(?<!\w) thinking\b');
  static const _thinkLines = 2;
  static const _minBuffer = 3;
  int _pendingLines = 0;
  String _buffer = '';

  String feed(String chunk) {
    if (chunk.isEmpty) return '';
    _buffer += chunk;
    if (_pendingLines > 0 || _buffer.length >= _minBuffer) {
      return _process();
    }
    return '';
  }

  String _process() {
    if (_pendingLines > 0) {
      _consumeLines();
      if (_pendingLines > 0) return '';
    }

    final output = StringBuffer();

    while (_buffer.isNotEmpty) {
      final match = _thinkRE.firstMatch(_buffer);
      if (match != null) {
        output.write(_buffer.substring(0, match.start));
        _buffer = _buffer.substring(match.end);
        final restNewline = _buffer.indexOf('\n');
        if (restNewline >= 0) {
          _buffer = _buffer.substring(restNewline + 1);
        } else {
          _buffer = '';
        }
        _pendingLines = _thinkLines;
        _consumeLines();
        if (_pendingLines > 0) break;
      } else {
        output.write(_buffer);
        _buffer = '';
      }
    }

    return output.toString().replaceAll('\n', ' ');
  }

  void _consumeLines() {
    while (_pendingLines > 0 && _buffer.isNotEmpty) {
      final newlineIdx = _buffer.indexOf('\n');
      if (newlineIdx >= 0) {
        _buffer = _buffer.substring(newlineIdx + 1);
      } else {
        _buffer = '';
      }
      _pendingLines--;
    }
  }

  String finish() {
    if (_pendingLines > 0) return '';
    final result = _buffer;
    _buffer = '';
    return result;
  }

  void reset() {
    _buffer = '';
    _pendingLines = 0;
  }
}
