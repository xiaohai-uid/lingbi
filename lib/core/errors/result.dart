import 'app_error.dart';

/// Result 类型 — 函数式错误处理
sealed class Result<T> {
  const Result();

  /// 处理成功和失败两种情况（穷尽匹配）
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  });

  /// 转换成功值
  Result<R> map<R>(R Function(T value) transform);

  /// 链式操作（flatMap）
  Result<R> flatMap<R>(Result<R> Function(T value) transform);

  /// 错误时降级
  Result<T> onError(AppError Function(AppError error) handler);

  /// 在边界处抛出异常（慎用）
  T orThrow() => when(
        success: (v) => v,
        failure: (e) => throw e,
      );

  /// 创建成功
  static Result<T> success<T>(T value) => Success(value);

  /// 创建失败
  static Result<T> failure<T>(AppError error) => Failure(error);
}

/// 成功结果
class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      success(value);

  @override
  Result<R> map<R>(R Function(T value) transform) =>
      Result.success(transform(value));

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      transform(value);

  @override
  Result<T> onError(AppError Function(AppError error) handler) => this;
}

/// 失败结果
class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      failure(error);

  @override
  Result<R> map<R>(R Function(T value) transform) =>
      Result.failure(error);

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) transform) =>
      Result.failure(error);

  @override
  Result<T> onError(AppError Function(AppError error) handler) =>
      Result.failure(handler(error));
}