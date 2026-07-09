import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

import '../lib/proxy.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  group('routeToMicroservice', () {
    test('routes /api/v1/ai requests to port 8081', () {
      final config = routeToMicroservice('/api/v1/ai/translate');
      expect(config, isNotNull);
      expect(config!.port, equals(8081));
      expect(config.pathPrefix, equals('/api/v1/ai'));
    });

    test('routes /api/v1/project requests to port 8082', () {
      final config = routeToMicroservice('/api/v1/project/list');
      expect(config, isNotNull);
      expect(config!.port, equals(8082));
    });

    test('routes /api/v1/document requests to port 8083', () {
      final config = routeToMicroservice('/api/v1/document/save');
      expect(config, isNotNull);
      expect(config!.port, equals(8083));
    });

    test('routes /api/v1/codex requests to port 8084', () {
      final config = routeToMicroservice('/api/v1/codex/refactor');
      expect(config, isNotNull);
      expect(config!.port, equals(8084));
    });

    test('routes /api/v1/export requests to port 8085', () {
      final config = routeToMicroservice('/api/v1/export/pdf');
      expect(config, isNotNull);
      expect(config!.port, equals(8085));
    });

    test('routes /api/v1/version requests to port 8086', () {
      final config = routeToMicroservice('/api/v1/version/check');
      expect(config, isNotNull);
      expect(config!.port, equals(8086));
    });

    test('routes /api/v1/settings requests to port 8087', () {
      final config = routeToMicroservice('/api/v1/settings/get');
      expect(config, isNotNull);
      expect(config!.port, equals(8087));
    });

    test('routes /api/v1/quota requests to port 8088', () {
      final config = routeToMicroservice('/api/v1/quota/usage');
      expect(config, isNotNull);
      expect(config!.port, equals(8088));
    });

    test('routes /api/v1/storage requests to port 8089', () {
      final config = routeToMicroservice('/api/v1/storage/upload');
      expect(config, isNotNull);
      expect(config!.port, equals(8089));
    });

    test('routes /api/v1/sync requests to port 8090', () {
      final config = routeToMicroservice('/api/v1/sync/cloud');
      expect(config, isNotNull);
      expect(config!.port, equals(8090));
    });

    test('routes /api/v1/canvas requests to port 8091', () {
      final config = routeToMicroservice('/api/v1/canvas/layout');
      expect(config, isNotNull);
      expect(config!.port, equals(8091));
    });

    test('returns null for unknown paths', () {
      final config = routeToMicroservice('/unknown/path');
      expect(config, isNull);
    });

    test('returns null for root path', () {
      final config = routeToMicroservice('/');
      expect(config, isNull);
    });
  });

  group('microservices list', () {
    test('contains exactly 11 microservices', () {
      expect(microservices.length, equals(11));
    });

    test('ports are 8081 through 8091', () {
      final expectedPorts = List.generate(11, (i) => 8081 + i);
      final actualPorts = microservices.map((c) => c.port).toList();
      expect(actualPorts, equals(expectedPorts));
    });

    test('all path prefixes are unique', () {
      final prefixes = microservices.map((c) => c.pathPrefix).toSet();
      expect(prefixes.length, equals(11));
    });
  });
}
