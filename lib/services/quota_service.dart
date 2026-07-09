import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QuotaService {
  QuotaService();
  int _dailyUsage = 0;
  final int _dailyLimit = 100;
  DateTime _lastReset = DateTime.now();

  int get dailyUsage => _dailyUsage;
  int get dailyLimit => _dailyLimit;
  int get remaining => _dailyLimit - _dailyUsage;

  bool get canUse => _dailyUsage < _dailyLimit;

  // ─── 会员（爱发电 tokens.json 本地激活）───
  bool _isMember = false;
  bool get isMember => _isMember;

  /// 读取本地会员标记（启动时调用，确保重启后保持会员态）
  Future<void> loadMemberState() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final flag = File('${dir.path}/.lingbi_member');
      _isMember = await flag.exists();
    } catch (_) {
      _isMember = false;
    }
  }

  /// 验证并激活会员令牌（tokens.json）
  ///
  /// tokens.json 结构示例:
  /// { "token": "<随机串>", "type": "member", "issuedAt": "<ISO8601>" }
  /// 校验通过则写入本地标记文件，返回 true。
  Future<bool> activateMemberToken() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/tokens.json');
      if (!await file.exists()) return false;
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final token = json['token'] as String? ?? '';
      final type = json['type'] as String? ?? '';
      if (token.length < 16 || type != 'member') return false;
      // 本地结构校验通过：写入会员标记（无服务端验签，捐赠后手动放置令牌）
      final flag = File('${dir.path}/.lingbi_member');
      await flag.writeAsString('active');
      _isMember = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取消会员（用于调试/退出登录）
  Future<void> deactivateMember() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final flag = File('${dir.path}/.lingbi_member');
      if (await flag.exists()) await flag.delete();
    } catch (_) {}
    _isMember = false;
  }

  void _checkReset() {
    final now = DateTime.now();
    if (_lastReset.day != now.day) {
      _dailyUsage = 0;
      _lastReset = now;
    }
  }

  bool tryConsume() {
    _checkReset();
    if (_dailyUsage >= _dailyLimit) return false;
    _dailyUsage++;
    return true;
  }

  void reset() {
    _dailyUsage = 0;
    _lastReset = DateTime.now();
  }
}
