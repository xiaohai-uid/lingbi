import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/models/story_beat.dart';
import 'package:lingbi/shared/errors/result.dart';
import 'package:lingbi/shared/errors/app_error.dart';

void main() {
  group('StoryBeat', () {
    test('creates with default values', () {
      final beat = StoryBeat(projectId: 'proj-1', title: '开场');
      expect(beat.projectId, 'proj-1');
      expect(beat.title, '开场');
      expect(beat.description, '');
      expect(beat.colorIndex, 0);
      expect(beat.sequence, 0);
      expect(beat.id.isNotEmpty, true);
    });

    test('serializes to/from JSON', () {
      final beat = StoryBeat(
        id: 'beat-1',
        projectId: 'proj-1',
        title: '高潮',
        description: '故事最高潮',
        colorIndex: 3,
        sequence: 4,
      );
      final json = beat.toJson();
      final restored = StoryBeat.fromJson(json);
      expect(restored.id, 'beat-1');
      expect(restored.title, '高潮');
      expect(restored.description, '故事最高潮');
      expect(restored.colorIndex, 3);
      expect(restored.sequence, 4);
    });

    test('copyWith preserves unchanged fields', () {
      final beat = StoryBeat(projectId: 'proj-1', title: '开场', description: '开始');
      final updated = beat.copyWith(description: '新的开始');
      expect(updated.title, '开场');
      expect(updated.description, '新的开始');
      expect(updated.colorIndex, 0);
      expect(updated.projectId, 'proj-1');
    });

    test('toJson contains all fields', () {
      final beat = StoryBeat(projectId: 'proj-1', title: '测试');
      final json = beat.toJson();
      expect(json.containsKey('id'), true);
      expect(json.containsKey('projectId'), true);
      expect(json.containsKey('title'), true);
      expect(json.containsKey('description'), true);
      expect(json.containsKey('colorIndex'), true);
      expect(json.containsKey('sequence'), true);
    });
  });

  group('Result<T>', () {
    test('Success holds value', () {
      final result = Result.success(42);
      result.when(
        success: (v) => expect(v, 42),
        failure: (_) => fail('should not be failure'),
      );
    });

    test('Failure holds error', () {
      final result = Result.failure<int>(DatabaseError('DB error'));
      result.when(
        success: (_) => fail('should not be success'),
        failure: (e) => expect(e.message, 'DB error'),
      );
    });

    test('map transforms success value', () {
      final result = Result.success('hello');
      final mapped = result.map((s) => s.length);
      mapped.when(
        success: (v) => expect(v, 5),
        failure: (_) => fail('should not be failure'),
      );
    });

    test('map skips failure', () {
      final result = Result.failure<String>(DatabaseError('error'));
      final mapped = result.map((s) => s.length);
      mapped.when(
        success: (_) => fail('should not be success'),
        failure: (e) => expect(e.message, 'error'),
      );
    });

    test('orThrow returns value on success', () {
      final result = Result.success(123);
      expect(result.orThrow(), 123);
    });

    test('orThrow throws on failure', () {
      final result = Result.failure<int>(DatabaseError('fail'));
      expect(() => result.orThrow(), throwsA(isA<DatabaseError>()));
    });

    test('flatMap chains successes', () {
      final r1 = Result.success(5);
      final r2 = r1.flatMap((v) => Result.success(v * 2));
      r2.when(
        success: (v) => expect(v, 10),
        failure: (_) => fail('should not be failure'),
      );
    });

    test('flatMap short-circuits on failure', () {
      final r1 = Result.failure<int>(DatabaseError('fail'));
      final r2 = r1.flatMap((v) => Result.success(v * 2));
      r2.when(
        success: (_) => fail('should not be success'),
        failure: (e) => expect(e.message, 'fail'),
      );
    });
  });

  group('AppError', () {
    test('DatabaseError carries message', () {
      final err = DatabaseError('connection failed', code: 'DB001');
      expect(err.message, 'connection failed');
      expect(err.code, 'DB001');
    });

    test('NetworkError carries message', () {
      final err = NetworkError('timeout');
      expect(err.message, 'timeout');
    });

    test('FileError carries message', () {
      final err = FileError('file not found');
      expect(err.message, 'file not found');
    });

    test('AIError carries message', () {
      final err = AIError('rate limit exceeded', code: '429');
      expect(err.code, '429');
    });

    test('toString returns message', () {
      final err = DatabaseError('test error');
      expect(err.toString(), 'test error');
    });
  });
}
