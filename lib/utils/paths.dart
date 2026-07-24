import 'dart:io';

/// 统一默认项目根目录: %USERPROFILE%\Documents\灵笔
///
/// [userProfile] 用于测试注入；为 null 时从环境变量读取。
String resolveDefaultProjectRoot({String? userProfile}) {
  final up = userProfile ?? Platform.environment['USERPROFILE'];
  if (up != null && up.isNotEmpty) {
    return '$up\\Documents\\灵笔';
  }
  throw UnsupportedError(
    '无法确定默认本地目录。请设置 USERPROFILE 环境变量，'
    '或手动指定工作目录。',
  );
}
