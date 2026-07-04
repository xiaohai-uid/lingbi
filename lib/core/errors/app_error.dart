/// 应用错误类型体系
sealed class AppError {
  final String message;
  final String? code;
  final Object? cause;

  AppError(this.message, {this.code, this.cause});

  @override
  String toString() => message;
}

/// 数据库错误
class DatabaseError extends AppError {
  DatabaseError(super.message, {super.code, super.cause});
}

/// 网络错误
class NetworkError extends AppError {
  NetworkError(super.message, {super.code, super.cause});
}

/// 文件系统错误
class FileError extends AppError {
  FileError(super.message, {super.code, super.cause});
}

/// AI 服务错误
class AIError extends AppError {
  AIError(super.message, {super.code, super.cause});
}