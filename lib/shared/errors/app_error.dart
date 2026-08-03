/// Typed fail-closed error categories used by the commercial mutation
/// protocol. Their wire names are stable journal/API values.
enum MutationErrorCode {
  projectRootAmbiguity('PROJECT_ROOT_AMBIGUITY'),
  pathEscape('PATH_ESCAPE'),
  revisionConflict('REVISION_CONFLICT'),
  unresolvedRecovery('UNRESOLVED_RECOVERY'),
  migrationRequired('MIGRATION_REQUIRED'),
  protocolUnavailable('PROTOCOL_UNAVAILABLE'),
  storageFailure('STORAGE_FAILURE');

  const MutationErrorCode(this.wireName);

  final String wireName;

  static MutationErrorCode fromWire(String value) {
    for (final code in values) {
      if (code.wireName == value) return code;
    }
    throw FormatException('Unknown MutationErrorCode: $value');
  }

  /// Alias matching the domain phrase used by ADR-012.
  static const projectRootAmbiguous = projectRootAmbiguity;
}

MutationErrorCode? _typedMutationCode(String? code) {
  if (code == null) return null;
  for (final typedCode in MutationErrorCode.values) {
    if (typedCode.wireName == code) return typedCode;
  }
  return null;
}

/// 应用错误类型体系
abstract class AppError {
  AppError(this.message,
      {String? code, this.cause, MutationErrorCode? typedCode})
      : code = code ?? typedCode?.wireName,
        typedCode = typedCode ?? _typedMutationCode(code);
  final String message;
  final String? code;
  final Object? cause;
  final MutationErrorCode? typedCode;

  @override
  String toString() => message;
}

/// 数据库错误
class DatabaseError extends AppError {
  DatabaseError(super.message, {super.code, super.cause, super.typedCode});
}

/// 网络错误
class NetworkError extends AppError {
  NetworkError(super.message, {super.code, super.cause, super.typedCode});
}

/// 文件系统错误
class FileError extends AppError {
  FileError(super.message, {super.code, super.cause, super.typedCode});
}

/// AI 服务错误
class AIError extends AppError {
  AIError(super.message, {super.code, super.cause, super.typedCode});
}
