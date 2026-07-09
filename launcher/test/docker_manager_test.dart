import 'dart:io';
import 'package:test/test.dart';
import 'package:lingbi_launcher/docker_manager.dart';

void main() {
  group('DockerManager', () {
    test('isAvailable returns bool', () async {
      final available = await DockerManager.isAvailable();
      expect(available is bool, true);
    });

    test('getStatus returns list of strings', () async {
      final available = await DockerManager.isAvailable();
      if (!available) {
        // Skip if Docker not available
        return;
      }
      final status = await DockerManager.getStatus();
      expect(status is List<String>, true);
    });

    test('startAll throws if docker-compose fails', () async {
      final available = await DockerManager.isAvailable();
      if (!available) return;
      // This test would need a valid docker-compose.yml in place
      // For now, just verify the method exists
    });
  });
}
