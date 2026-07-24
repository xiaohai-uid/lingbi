import 'package:flutter_test/flutter_test.dart';
import 'package:launcher/service_manager.dart';

void main() {
  group('ServiceConfig', () {
    test('creates with required fields', () {
      final config = ServiceConfig(
        command: 'dart',
        args: ['run', 'bin/server.dart'],
        cwd: 'test/path',
        port: 8080,
        env: {'PORT': '8080'},
      );
      expect(config.command, 'dart');
      expect(config.args, ['run', 'bin/server.dart']);
      expect(config.cwd, 'test/path');
      expect(config.port, 8080);
      expect(config.env, {'PORT': '8080'});
    });

    test('port is integer', () {
      final config = ServiceConfig(
        command: 'dart',
        args: [],
        cwd: '.',
        port: 8084,
        env: {},
      );
      expect(config.port, isA<int>());
    });
  });

  group('ServiceStatus', () {
    test('has all expected values', () {
      expect(ServiceStatus.values.length, 5);
      expect(ServiceStatus.values, contains(ServiceStatus.stopped));
      expect(ServiceStatus.values, contains(ServiceStatus.starting));
      expect(ServiceStatus.values, contains(ServiceStatus.running));
      expect(ServiceStatus.values, contains(ServiceStatus.error));
      expect(ServiceStatus.values, contains(ServiceStatus.degraded));
    });
  });

  group('ServiceManager', () {
    test('getConfig returns config for known services', () {
      final config = ServiceManager.getConfig('API Gateway');
      expect(config, isNotNull);
      expect(config!.port, 8080);
    });

    test('getConfig returns Canon config with correct port', () {
      final config = ServiceManager.getConfig('Canon');
      expect(config, isNotNull);
      expect(config!.port, 8084);
      expect(config.cwd, contains('canon'));
    });

    test('getConfig returns null for unknown service', () {
      final config = ServiceManager.getConfig('UnknownService');
      expect(config, isNull);
    });

    test('all microservice ports are in range 8080-8093', () {
      final services = [
        'API Gateway', 'AI Provider', 'Project', 'Document',
        'Canon', 'Export', 'Version', 'Settings',
        'Quota', 'Storage', 'Sync', 'Canvas',
      ];
      for (final name in services) {
        final config = ServiceManager.getConfig(name);
        expect(config, isNotNull, reason: '$name not found');
        expect(config!.port, greaterThanOrEqualTo(8080));
        expect(config.port, lessThanOrEqualTo(8093));
      }
    });

    test('Canon service uses canon directory', () {
      final config = ServiceManager.getConfig('Canon');
      expect(config!.cwd, contains('canon'));
      expect(config.cwd, isNot(contains('codex')));
    });
  });
}
