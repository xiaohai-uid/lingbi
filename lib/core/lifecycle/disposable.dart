/// 可释放资源接口
///
/// 实现此接口表示该对象持有需要显式释放的资源
/// （例如 Timer、StreamSubscription、文件句柄等）。
abstract class Disposable {
  /// 释放所有持有的资源
  ///
  /// 调用后对象应不再可用。重复调用应安全（幂等）。
  Future<void> dispose();
}