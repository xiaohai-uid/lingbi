import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/shared/ai/model_registry.dart';
import 'package:lingbi/shared/ai/task_model_runtime.dart';
import 'package:lingbi/shared/errors/ai_error.dart';
import 'package:lingbi/shared/models/model_snapshot.dart';
import 'package:lingbi/services/model_router_service.dart';

void main() {
  group('TaskModelRuntime', () {
    test('planning, writing, and review freeze their routed model snapshot',
        () async {
      final router = ModelRouterService(
        config: const ModelRouteConfig(
          planningEndpointId: 'planning-endpoint',
          writingEndpointId: 'writing-endpoint',
          reviewEndpointId: 'review-endpoint',
        ),
        defaultEndpointId: 'local-endpoint',
      )..availableEndpoints = const [
          'planning-endpoint',
          'writing-endpoint',
          'review-endpoint',
          'local-endpoint',
        ];
      final snapshots = <String, ModelSnapshot>{
        'planning-endpoint': _snapshot('cloud', 'planning-model'),
        'writing-endpoint': _snapshot('cloud', 'writing-model'),
        'review-endpoint': _snapshot('cloud', 'review-model'),
        'local-endpoint': _snapshot('local', 'local-model'),
      };
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => snapshots[endpointId],
      );
      final requests = <TaskModelRequest>[
        TaskModelRequest.planning(taskId: 'plan', inputTokens: 100),
        TaskModelRequest.writing(taskId: 'write', inputTokens: 100),
        TaskModelRequest.review(taskId: 'review', inputTokens: 100),
      ];

      final selectedModels = <String>[];
      for (final request in requests) {
        final result = await runtime.run<String>(
          request,
          (invocation) async {
            selectedModels.add(invocation.snapshot.modelId);
            router.setRoute(
              switch (request.kind) {
                TaskModelKind.planning => RouteSlot.planning,
                TaskModelKind.writing => RouteSlot.writing,
                TaskModelKind.review => RouteSlot.review,
              },
              'local-endpoint',
            );
            return TaskModelOutput(
              value: invocation.snapshot.modelId,
              inputTokens: 100,
              outputTokens: 20,
            );
          },
        );
        expect(result.snapshot.modelId, result.value);
      }

      expect(
        selectedModels,
        const ['planning-model', 'writing-model', 'review-model'],
      );
    });

    test('budget cap selects an affordable fallback before execution',
        () async {
      final router = ModelRouterService(
        config: const ModelRouteConfig(writingEndpointId: 'premium'),
        defaultEndpointId: 'local',
        fallbackEndpointIds: const ['economy'],
        localEndpointIds: const {'local'},
      )..availableEndpoints = const ['premium', 'economy', 'local'];
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => switch (endpointId) {
          'premium' => _snapshot(
              'cloud',
              'premium-model',
              pricing: const ModelPricing(
                inputPerMillion: 10,
                outputPerMillion: 30,
              ),
            ),
          'economy' => _snapshot(
              'cloud',
              'economy-model',
              pricing: const ModelPricing(
                inputPerMillion: 1,
                outputPerMillion: 2,
              ),
            ),
          'local' => _snapshot('local', 'local-model'),
          _ => null,
        },
      );

      final result = await runtime.run<String>(
        TaskModelRequest.writing(
          taskId: 'budgeted-write',
          inputTokens: 1000000,
          maxOutputTokens: 1000000,
          budgetCap: 5,
        ),
        (invocation) async => TaskModelOutput(
          value: invocation.snapshot.modelId,
          inputTokens: 1000000,
          outputTokens: 500000,
        ),
      );

      expect(result.value, 'economy-model');
      expect(result.fallbackReason, TaskModelFallbackReason.budgetCap);
    });

    test('budget cap prevents execution when no candidate cost is bounded',
        () async {
      final router = ModelRouterService(
        config: const ModelRouteConfig(writingEndpointId: 'unknown-price'),
        defaultEndpointId: 'remote-default',
      )..availableEndpoints = const ['unknown-price', 'remote-default'];
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => _snapshot('cloud', endpointId),
      );
      var executed = false;

      final future = runtime.run<void>(
        TaskModelRequest.writing(
          taskId: 'strict-budget',
          inputTokens: 100,
          budgetCap: 1,
        ),
        (_) async {
          executed = true;
          return const TaskModelOutput(
            value: null,
            inputTokens: 0,
            outputTokens: 0,
          );
        },
      );

      await expectLater(future, throwsA(isA<TaskModelBudgetExceeded>()));
      expect(executed, isFalse);
    });

    test('local-only mode excludes configured remote routes', () async {
      final router = ModelRouterService(
        config: const ModelRouteConfig(reviewEndpointId: 'remote'),
        defaultEndpointId: 'local',
        localEndpointIds: const {'local'},
      )..availableEndpoints = const ['remote', 'local'];
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => _snapshot(
          endpointId == 'local' ? 'local' : 'cloud',
          '$endpointId-model',
        ),
      );

      final result = await runtime.run<String>(
        TaskModelRequest.review(
          taskId: 'private-review',
          inputTokens: 100,
          localOnly: true,
        ),
        (invocation) async => TaskModelOutput(
          value: invocation.endpointId,
          inputTokens: 100,
          outputTokens: 20,
        ),
      );

      expect(result.value, 'local');
      expect(result.fallbackReason, TaskModelFallbackReason.localOnly);
    });

    test('execution is stopped by the task timeout', () async {
      final router = ModelRouterService(defaultEndpointId: 'local');
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => _snapshot('local', 'local-model'),
      );

      final future = runtime.run<void>(
        TaskModelRequest.planning(
          taskId: 'timed-plan',
          inputTokens: 10,
          timeout: const Duration(milliseconds: 5),
        ),
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return const TaskModelOutput(
            value: null,
            inputTokens: 10,
            outputTokens: 1,
          );
        },
      );

      await expectLater(future, throwsA(isA<TaskModelTimeout>()));
    });

    test('429 falls back to the next snapshot frozen at task start', () async {
      final router = ModelRouterService(
        config: const ModelRouteConfig(writingEndpointId: 'primary'),
        defaultEndpointId: 'local',
        fallbackEndpointIds: const ['secondary'],
        localEndpointIds: const {'local'},
      )..availableEndpoints = const ['primary', 'secondary', 'local'];
      final snapshots = <String, ModelSnapshot>{
        'primary': _snapshot('cloud', 'primary-model'),
        'secondary': _snapshot('cloud', 'secondary-model'),
        'local': _snapshot('local', 'local-model'),
      };
      final runtime = TaskModelRuntime(
        router: router,
        resolveSnapshot: (endpointId) => snapshots[endpointId],
      );
      final attempts = <String>[];

      final result = await runtime.run<String>(
        TaskModelRequest.writing(
          taskId: 'rate-limited-write',
          inputTokens: 100,
        ),
        (invocation) async {
          attempts.add(invocation.snapshot.modelId);
          if (invocation.endpointId == 'primary') {
            snapshots['secondary'] = _snapshot('cloud', 'changed-too-late');
            throw AIRateLimitError(message: '429; credential=sk-not-for-audit');
          }
          return TaskModelOutput(
            value: invocation.snapshot.modelId,
            inputTokens: 100,
            outputTokens: 25,
          );
        },
      );

      expect(attempts, const ['primary-model', 'secondary-model']);
      expect(result.initialSnapshot.modelId, 'primary-model');
      expect(result.snapshot.modelId, 'secondary-model');
      expect(result.fallbackReason, TaskModelFallbackReason.rateLimited);
    });
  });
}

ModelSnapshot _snapshot(
  String providerId,
  String modelId, {
  ModelPricing pricing = const ModelPricing(),
}) {
  return ModelSnapshot(
    providerId: providerId,
    modelId: modelId,
    displayName: modelId,
    pricing: pricing,
    capturedAt: DateTime.utc(2026, 7, 28),
  );
}
