/// 批量生成 + 任务队列 — 单元测试
///
/// 覆盖：队列调度/取消/重试/批量编排
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/task_queue_service.dart';

void main() {
  group('TaskQueueItem 数据模型', () {
    test('fromJson / toJson 往返一致', () {
      final item = TaskQueueItem(
        id: 'task_1',
        type: TaskType.batchGenerate,
        status: TaskStatus.running,
        progress: 0.5,
        retryCount: 1,
        label: '批量生成5章',
        createdAt: '2026-07-25T00:00:00.000',
      );

      final json = item.toJson();
      final restored = TaskQueueItem.fromJson(json);

      expect(restored.id, 'task_1');
      expect(restored.type, TaskType.batchGenerate);
      expect(restored.status, TaskStatus.running);
      expect(restored.progress, 0.5);
      expect(restored.retryCount, 1);
      expect(restored.label, '批量生成5章');
    });

    test('canRetry 判断', () {
      final item = TaskQueueItem(
        id: 't',
        type: TaskType.custom,
      );
      expect(item.canRetry, isTrue);

      item.retryCount = 3;
      expect(item.canRetry, isFalse);
    });

    test('isTerminal 判断', () {
      final item = TaskQueueItem(id: 't', type: TaskType.custom);
      expect(item.isTerminal, isFalse);

      item.status = TaskStatus.done;
      expect(item.isTerminal, isTrue);

      item.status = TaskStatus.cancelled;
      expect(item.isTerminal, isTrue);
    });
  });

  group('TaskQueueService 调度', () {
    late TaskQueueService service;

    setUp(() {
      service = TaskQueueService();
    });

    tearDown(() {
      service.dispose();
    });

    test('提交任务并执行完成', () async {
      service.registerExecutor(TaskType.custom, (task, report) async {
        report(0.5);
        report(1);
        return '执行结果';
      });

      final task = service.enqueue(type: TaskType.custom, label: '测试任务');
      final result = await service.waitForTask(task.id);

      expect(result, '执行结果');
      final completed = service.getTask(task.id)!;
      expect(completed.status, TaskStatus.done);
      expect(completed.progress, 1.0);
    });

    test('串行执行多个任务', () async {
      final executionOrder = <String>[];

      service.registerExecutor(TaskType.custom, (task, report) async {
        executionOrder.add(task.label);
        await Future.delayed(const Duration(milliseconds: 10));
        return task.label;
      });

      service.enqueue(type: TaskType.custom, label: 'A');
      service.enqueue(type: TaskType.custom, label: 'B');
      final taskC = service.enqueue(type: TaskType.custom, label: 'C');

      await service.waitForTask(taskC.id);

      expect(executionOrder, ['A', 'B', 'C']);
    });

    test('无执行器时任务失败', () async {
      final task = service.enqueue(type: TaskType.analysis, label: '无执行器');
      await service.waitForTask(task.id);

      final failed = service.getTask(task.id)!;
      expect(failed.status, TaskStatus.failed);
      expect(failed.error, contains('No executor'));
    });
  });

  group('取消', () {
    late TaskQueueService service;

    setUp(() {
      service = TaskQueueService();
    });

    tearDown(() {
      service.dispose();
    });

    test('取消待执行任务', () async {
      // 先占住执行器
      final blocker = Completer<void>();
      service.registerExecutor(TaskType.custom, (task, report) async {
        await blocker.future;
        return '';
      });

      service.enqueue(type: TaskType.custom, label: '阻塞');
      // 等待第一个任务开始执行
      await Future.delayed(const Duration(milliseconds: 50));

      final task2 = service.enqueue(type: TaskType.custom, label: '待取消');
      final cancelled = service.cancel(task2.id);

      expect(cancelled, isTrue);
      expect(service.getTask(task2.id)!.status, TaskStatus.cancelled);

      blocker.complete();
    });

    test('取消已完成任务返回 false', () async {
      service.registerExecutor(TaskType.custom, (task, report) async => 'ok');

      final task = service.enqueue(type: TaskType.custom, label: '快速');
      await service.waitForTask(task.id);

      expect(service.cancel(task.id), isFalse);
    });

    test('cancelAll 取消所有待执行', () async {
      final blocker = Completer<void>();
      service.registerExecutor(TaskType.custom, (task, report) async {
        await blocker.future;
        return '';
      });

      service.enqueue(type: TaskType.custom, label: '阻塞');
      await Future.delayed(const Duration(milliseconds: 50));

      service.enqueue(type: TaskType.custom, label: 'P1');
      service.enqueue(type: TaskType.custom, label: 'P2');
      service.enqueue(type: TaskType.custom, label: 'P3');

      final count = service.cancelAll();
      expect(count, 3);

      blocker.complete();
    });
  });

  group('重试', () {
    late TaskQueueService service;

    setUp(() {
      service = TaskQueueService();
    });

    tearDown(() {
      service.dispose();
    });

    test('失败自动重试（最多3次）', () async {
      var attempts = 0;
      service.registerExecutor(TaskType.custom, (task, report) async {
        attempts++;
        if (attempts < 3) throw Exception('模拟失败');
        return '第3次成功';
      });

      final task = service.enqueue(type: TaskType.custom, label: '重试测试');
      final result = await service.waitForTask(task.id);

      expect(result, '第3次成功');
      expect(attempts, 3);
      expect(service.getTask(task.id)!.status, TaskStatus.done);
    });

    test('超过最大重试次数标记 failed', () async {
      service.registerExecutor(TaskType.custom, (task, report) async {
        throw Exception('永远失败');
      });

      final task = service.enqueue(
        type: TaskType.custom,
        label: '必失败',
        maxRetries: 2,
      );
      await service.waitForTask(task.id);

      final failed = service.getTask(task.id)!;
      expect(failed.status, TaskStatus.failed);
      expect(failed.retryCount, 2);
    });

    test('手动重试失败任务', () async {
      var shouldFail = true;
      service.registerExecutor(TaskType.custom, (task, report) async {
        if (shouldFail) throw Exception('首次失败');
        return '重试成功';
      });

      final task = service.enqueue(
        type: TaskType.custom,
        label: '手动重试',
        maxRetries: 0, // 不自动重试
      );
      await service.waitForTask(task.id);
      expect(service.getTask(task.id)!.status, TaskStatus.failed);

      // 修复后手动重试
      shouldFail = false;
      service.retry(task.id);
      final result = await service.waitForTask(task.id);
      expect(result, '重试成功');
    });
  });

  group('批量生成编排', () {
    late TaskQueueService service;

    setUp(() {
      service = TaskQueueService();
    });

    tearDown(() {
      service.dispose();
    });

    test('createBatchGeneration 创建正确数量任务', () {
      service.registerExecutor(TaskType.singleChapter, (task, report) async {
        return '生成: ${task.metadata['chapter_id']}';
      });

      final ids = service.createBatchGeneration(
        const BatchGenerateRequest(
          projectId: 'proj1',
          chapterIds: ['ch1', 'ch2', 'ch3', 'ch4', 'ch5'],
          userInstruction: '加快节奏',
        ),
      );

      expect(ids.length, 5);
      expect(service.pendingCount + service.runningCount, greaterThan(0));
    });

    test('批量任务串行完成', () async {
      final completed = <String>[];
      service.registerExecutor(TaskType.singleChapter, (task, report) async {
        report(0.5);
        await Future.delayed(const Duration(milliseconds: 5));
        report(1);
        final chId = task.metadata['chapter_id'] as String;
        completed.add(chId);
        return 'done_$chId';
      });

      final ids = service.createBatchGeneration(
        const BatchGenerateRequest(
          projectId: 'proj1',
          chapterIds: ['ch1', 'ch2', 'ch3'],
        ),
      );

      // 等待最后一个完成
      await service.waitForTask(ids.last);

      expect(completed, ['ch1', 'ch2', 'ch3']);
      for (final id in ids) {
        expect(service.getTask(id)!.status, TaskStatus.done);
      }
    });

    test('enqueueBatch 通用批量提交', () async {
      service.registerExecutor(TaskType.analysis, (task, report) async {
        return task.label;
      });

      final ids = service.enqueueBatch(
        type: TaskType.analysis,
        labels: ['分析A', '分析B'],
      );

      expect(ids.length, 2);
      await service.waitForTask(ids.last);
      expect(service.getTask(ids[0])!.status, TaskStatus.done);
    });
  });

  group('进度上报', () {
    test('进度回调正确触发', () async {
      final service = TaskQueueService();
      final progressValues = <double>[];

      service.registerExecutor(TaskType.custom, (task, report) async {
        report(0.25);
        report(0.5);
        report(0.75);
        report(1);
        return 'ok';
      });

      service.onChanged = () {
        final tasks = service.getTasks();
        if (tasks.isNotEmpty && tasks.first.status == TaskStatus.running) {
          progressValues.add(tasks.first.progress);
        }
      };

      final task = service.enqueue(type: TaskType.custom, label: '进度');
      await service.waitForTask(task.id);

      expect(progressValues, contains(0.25));
      expect(progressValues, contains(1.0));
      service.dispose();
    });
  });
}
