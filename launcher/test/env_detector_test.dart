import 'package:flutter_test/flutter_test.dart';
import 'package:launcher/env_detector.dart';

void main() {
  group('EnvResult', () {
    test('creates with required fields', () {
      const result = EnvResult(
        name: 'Test',
        available: true,
        version: '1.0.0',
      );
      expect(result.name, 'Test');
      expect(result.available, true);
      expect(result.version, '1.0.0');
      expect(result.hint, isNull);
    });

    test('creates with hint', () {
      const result = EnvResult(
        name: 'Missing',
        available: false,
        hint: 'Please install',
      );
      expect(result.available, false);
      expect(result.hint, 'Please install');
    });
  });

  group('EnvDetector', () {
    test('detectAll returns 3 results', () async {
      final results = await EnvDetector.detectAll();
      expect(results.length, 3);
    });

    test('first result is Dart SDK', () async {
      final results = await EnvDetector.detectAll();
      expect(results[0].name, 'Dart SDK');
    });

    test('second result is Node.js', () async {
      final results = await EnvDetector.detectAll();
      expect(results[1].name, 'Node.js');
    });

    test('third result is port check', () async {
      final results = await EnvDetector.detectAll();
      expect(results[2].name, '端口检测');
    });
  });
}
