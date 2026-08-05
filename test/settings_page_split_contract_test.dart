import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings page split contract', () {
    test('settings facade stays under 500 lines', () {
      final lines = File(
        'lib/features/settings/ui/settings_page.dart',
      ).readAsLinesSync();

      expect(lines.length, lessThan(500));
    });

    test('expected settings section files exist', () {
      const sections = [
        'settings_section_scaffold.dart',
        'appearance_settings_section.dart',
        'editor_settings_section.dart',
        'ai_model_settings_section.dart',
        'api_key_settings_section.dart',
        'capability_settings_section.dart',
        'custom_endpoint_settings_section.dart',
        'shortcuts_settings_section.dart',
        'storage_settings_section.dart',
        'cloud_sync_settings_section.dart',
        'privacy_settings_section.dart',
        'subscription_settings_section.dart',
      ];

      for (final name in sections) {
        final path = 'lib/features/settings/ui/sections/$name';
        expect(File(path).existsSync(), isTrue, reason: 'missing $path');
      }
    });
  });
}
