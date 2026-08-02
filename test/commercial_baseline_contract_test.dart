import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';

void main() {
  test('current schema versions are explicit positive integers', () {
    expect(SchemaVersions.project, greaterThan(0));
    expect(SchemaVersions.settings, greaterThan(0));
    expect(SchemaVersions.portablePackage, greaterThan(0));
  });

  test('legacy project fixture remains a version one contract', () {
    final file = File('test/fixtures/legacy_project_v1/.lingbi/project.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(json['schemaVersion'], 1);
    expect(json['name'], '旧版玄幻项目');
    expect(json['genre'], '玄幻');
  });

  test('legacy settings fixture contains no plaintext API keys', () {
    final file = File('test/fixtures/legacy_settings_v1.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(json['schemaVersion'], 1);
    expect(json.containsKey('apiKeys'), isFalse);
  });
}
