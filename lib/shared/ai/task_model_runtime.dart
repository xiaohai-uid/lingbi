import 'dart:async';

import '../errors/ai_error.dart';
import '../models/model_snapshot.dart';

enum TaskModelKind { planning, writing, review }

enum TaskModelFallbackReason {
  defaultRoute,
  unavailable,
  budgetCap,
  rateLimited,
  localOnly,
}

class TaskModelRoute {
  const TaskModelRoute({
    required this.endpointId,
    required this.isFallback,
    this.fallbackReason,
    this.isLocal = false,
  });

  final String endpointId;
  final bool isFallback;
  final TaskModelFallbackReason? fallbackReason;
  final bool isLocal;
}

abstract interface class TaskModelRouter {
  List<TaskModelRoute> resolveCandidates(
    TaskModelKind kind, {
    bool localOnly = false,
  });
}

typedef TaskModelSnapshotResolver = ModelSnapshot? Function(String endpointId);
typedef TaskModelExecutor<T> = Future<TaskModelOutput<T>> Function(
  TaskModelInvocation invocation,
);

class TaskModelRequest {
  const TaskModelRequest({
    required this.taskId,
    required this.kind,
    required this.inputTokens,
    this.maxOutputTokens = 2048,
    this.budgetCap,
    this.timeout = const Duration(seconds: 60),
    this.localOnly = false,
  });

  factory TaskModelRequest.planning({
    required String taskId,
    required int inputTokens,
    int maxOutputTokens = 2048,
    double? budgetCap,
    Duration timeout = const Duration(seconds: 60),
    bool localOnly = false,
  }) =>
      TaskModelRequest(
        taskId: taskId,
        kind: TaskModelKind.planning,
        inputTokens: inputTokens,
        maxOutputTokens: maxOutputTokens,
        budgetCap: budgetCap,
        timeout: timeout,
        localOnly: localOnly,
      );

  factory TaskModelRequest.writing({
    required String taskId,
    required int inputTokens,
    int maxOutputTokens = 2048,
    double? budgetCap,
    Duration timeout = const Duration(seconds: 60),
    bool localOnly = false,
  }) =>
      TaskModelRequest(
        taskId: taskId,
        kind: TaskModelKind.writing,
        inputTokens: inputTokens,
        maxOutputTokens: maxOutputTokens,
        budgetCap: budgetCap,
        timeout: timeout,
        localOnly: localOnly,
      );

  factory TaskModelRequest.review({
    required String taskId,
    required int inputTokens,
    int maxOutputTokens = 2048,
    double? budgetCap,
    Duration timeout = const Duration(seconds: 60),
    bool localOnly = false,
  }) =>
      TaskModelRequest(
        taskId: taskId,
        kind: TaskModelKind.review,
        inputTokens: inputTokens,
        maxOutputTokens: maxOutputTokens,
        budgetCap: budgetCap,
        timeout: timeout,
        localOnly: localOnly,
      );

  final String taskId;
  final TaskModelKind kind;
  final int inputTokens;
  final int maxOutputTokens;
  final double? budgetCap;
  final Duration timeout;
  final bool localOnly;
}

class TaskModelInvocation {
  const TaskModelInvocation({
    required this.taskId,
    required this.kind,
    required this.endpointId,
    required this.snapshot,
    required this.maxOutputTokens,
  });

  final String taskId;
  final TaskModelKind kind;
  final String endpointId;
  final ModelSnapshot snapshot;
  final int maxOutputTokens;
}

class TaskModelOutput<T> {
  const TaskModelOutput({
    required this.value,
    required this.inputTokens,
    required this.outputTokens,
  });

  final T value;
  final int inputTokens;
  final int outputTokens;
}

class TaskModelResult<T> {
  const TaskModelResult({
    required this.value,
    required this.initialSnapshot,
    required this.snapshot,
    required this.fallbackReason,
  });

  final T value;
  final ModelSnapshot initialSnapshot;
  final ModelSnapshot snapshot;
  final TaskModelFallbackReason? fallbackReason;
}

class TaskModelBudgetExceeded implements Exception {
  const TaskModelBudgetExceeded(this.budgetCap);

  final double budgetCap;

  @override
  String toString() =>
      'TaskModelBudgetExceeded: no model fits budget $budgetCap';
}

class TaskModelTimeout implements Exception {
  const TaskModelTimeout(this.timeout);

  final Duration timeout;

  @override
  String toString() => 'TaskModelTimeout: exceeded $timeout';
}

class _ResolvedTaskModelRoute {
  const _ResolvedTaskModelRoute(this.route, this.snapshot);

  final TaskModelRoute route;
  final ModelSnapshot snapshot;
}

class TaskModelRuntime {
  const TaskModelRuntime({
    required TaskModelRouter router,
    required TaskModelSnapshotResolver resolveSnapshot,
  })  : _router = router,
        _resolveSnapshot = resolveSnapshot;

  final TaskModelRouter _router;
  final TaskModelSnapshotResolver _resolveSnapshot;

  Future<TaskModelResult<T>> run<T>(
    TaskModelRequest request,
    TaskModelExecutor<T> execute,
  ) async {
    final routes = _router.resolveCandidates(
      request.kind,
      localOnly: request.localOnly,
    );
    if (routes.isEmpty) {
      throw StateError('No model route is available for ${request.kind.name}');
    }
    final resolvedRoutes = <_ResolvedTaskModelRoute>[];
    var skippedForBudget = false;
    for (final route in routes) {
      final snapshot = _resolveSnapshot(route.endpointId);
      if (snapshot == null) continue;
      if (!_fitsBudget(request, route, snapshot)) {
        skippedForBudget = true;
        continue;
      }
      resolvedRoutes.add(_ResolvedTaskModelRoute(route, snapshot));
    }
    if (resolvedRoutes.isEmpty) {
      final cap = request.budgetCap;
      if (cap != null) throw TaskModelBudgetExceeded(cap);
      throw StateError('No model snapshot is available for ${request.kind.name}');
    }
    final initial = resolvedRoutes.first;
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < resolvedRoutes.length; index++) {
      final selected = resolvedRoutes[index];
      final remaining = request.timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) throw TaskModelTimeout(request.timeout);
      try {
        final output = await execute(TaskModelInvocation(
          taskId: request.taskId,
          kind: request.kind,
          endpointId: selected.route.endpointId,
          snapshot: selected.snapshot,
          maxOutputTokens: request.maxOutputTokens,
        )).timeout(remaining);
        return TaskModelResult(
          value: output.value,
          initialSnapshot: initial.snapshot,
          snapshot: selected.snapshot,
          fallbackReason: index > 0
              ? TaskModelFallbackReason.rateLimited
              : skippedForBudget
                  ? TaskModelFallbackReason.budgetCap
                  : selected.route.fallbackReason,
        );
      } on TimeoutException {
        throw TaskModelTimeout(request.timeout);
      } on AIRateLimitError {
        if (index + 1 >= resolvedRoutes.length) rethrow;
      }
    }
    throw StateError('No model execution completed for ${request.taskId}');
  }

  bool _fitsBudget(
    TaskModelRequest request,
    TaskModelRoute route,
    ModelSnapshot snapshot,
  ) {
    final cap = request.budgetCap;
    if (cap == null) return true;
    if (!snapshot.pricing.isKnown) return route.isLocal;
    final maximumCost = snapshot.pricing.estimateCost(
      inputTokens: request.inputTokens,
      outputTokens: request.maxOutputTokens,
    );
    return maximumCost <= cap;
  }
}
