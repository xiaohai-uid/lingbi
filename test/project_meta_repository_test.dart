import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/interfaces/i_project_meta_repository.dart';

void main() {
  group('WorldConstitution', () {
    test('creates with default values', () {
      const wc = WorldConstitution();
      expect(wc.hardInvariants, isEmpty);
      expect(wc.softGuidance, isEmpty);
    });

    test('creates with values', () {
      const wc = WorldConstitution(
        hardInvariants: ['主角不能死'],
        softGuidance: ['多使用对话推进剧情'],
      );
      expect(wc.hardInvariants, ['主角不能死']);
      expect(wc.softGuidance, ['多使用对话推进剧情']);
    });

    test('serializes to JSON', () {
      const wc = WorldConstitution(
        hardInvariants: ['主角不能死', '力量体系不崩'],
        softGuidance: ['每章至少一个冲突'],
      );
      final json = wc.toJson();
      expect(json['hardInvariants'], ['主角不能死', '力量体系不崩']);
      expect(json['softGuidance'], ['每章至少一个冲突']);
    });

    test('deserializes from JSON', () {
      final json = {
        'hardInvariants': ['主角不能死'],
        'softGuidance': ['多使用对话'],
      };
      final wc = WorldConstitution.fromJson(json);
      expect(wc.hardInvariants, ['主角不能死']);
      expect(wc.softGuidance, ['多使用对话']);
    });

    test('deserializes from empty JSON', () {
      final wc = WorldConstitution.fromJson({});
      expect(wc.hardInvariants, isEmpty);
      expect(wc.softGuidance, isEmpty);
    });
  });
}
