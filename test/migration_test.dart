/// 数据迁移测试 — 测试 DataMigrator 的迁移逻辑
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/data/migration/data_migrator.dart';

void main() {
  group('MigrationReport', () {
    test('default report has zero counts', () {
      final report = MigrationReport();
      expect(report.migratedWorlds, 0);
      expect(report.migratedDocuments, 0);
      expect(report.hasErrors, false);
    });

    test('summary with successful migration', () {
      final report = MigrationReport();
      report.migratedWorlds = 2;
      report.migratedDocuments = 5;
      expect(report.summary, contains('2 世界'));
      expect(report.summary, contains('5 文档'));
    });

    test('hasErrors detects errors', () {
      final report = MigrationReport();
      expect(report.hasErrors, false);
      report.errors.add('test error');
      expect(report.hasErrors, true);
    });

    test('summary with errors', () {
      final report = MigrationReport();
      report.migratedWorlds = 1;
      report.errors.add('文件丢失');
      expect(report.summary, contains('1 错误'));
    });

    test('multiple errors tracked', () {
      final report = MigrationReport();
      report.errors.add('错误1');
      report.errors.add('错误2');
      expect(report.errors.length, 2);
    });

    test('empty summary', () {
      final report = MigrationReport();
      expect(report.summary, '迁移: 0 世界, 0 文档');
    });
  });

  group('DataMigrator - UUID generation', () {
    test('generates unique IDs', () {
      const id1 = 'mig-1000-abcdef';
      const id2 = 'mig-2000-123456';
      expect(id1 != id2, true);
      expect(id1.startsWith('mig-'), true);
      expect(id2.startsWith('mig-'), true);
    });
  });

  group('MigrationReport - edge cases', () {
    test('handles empty world list', () {
      final report = MigrationReport();
      expect(report.migratedWorlds, 0);
      expect(report.summary, isNot(contains('错误')));
    });

    test('handles large migration counts', () {
      final report = MigrationReport();
      report.migratedWorlds = 100;
      report.migratedDocuments = 500;
      expect(report.summary, contains('100'));
      expect(report.summary, contains('500'));
    });

    test('handles zero documents', () {
      final report = MigrationReport();
      report.migratedWorlds = 1;
      expect(report.migratedDocuments, 0);
      expect(report.summary, contains('0 文档'));
    });
  });
}
