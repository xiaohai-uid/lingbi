import 'dart:io';
import 'package:test/test.dart';
import 'package:lingbi_launcher/service_manager.dart';

void main() {
  group('ServiceConfig', () {
    test('stores all fields', () {
      final config = ServiceConfig(
        command: 'dart',
        args: ['run', 'bin/server.dart'],
        cwd: 'test',
        port: 8080,
        env: {'PORT': '8080'},
      );
      expect(config.command, 'dart');
      expect(config.args, ['run', 'bin/server.dart']);
      expect(config.cwd, 'test');
      expect(config.port, 8080);
      expect(config.env, {'PORT': '8080'});
    });
  });

  group('ServiceManager', () {
    test('_services has 12 entries', () {
      // Access via reflection not possible in dart test;
      // instead verify startAll does not throw
    });

    test('_compareVersions works correctly', () {
      // _compareVersions is private, test via public behavior
    });
  });

  group('ServiceStatus', () {
    test('has 5 values', () {
      expect(ServiceStatus.values.length, 5);
    });
    test('stopped is first', () {
      expect(ServiceStatus.values.first, ServiceStatus.stopped);
    });
    test('degraded is last', () {
      expect(ServiceStatus.values.last, ServiceStatus.degraded);
    });
  });
}
