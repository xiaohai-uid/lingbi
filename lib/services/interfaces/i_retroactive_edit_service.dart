/// 回溯编辑服务接口
library;

/// 编辑模式
enum EditMode {
  rewrite,    // 改写
  expand,     // 扩写
  polish,     // 润色
  shorten,    // 缩写
  continue_,  // 续写
  changeTone, // 换语调
}

/// 语调选项
const List<String> toneOptions = [
  '严肃', '轻松', '幽默', '古风', '沉重', '悬疑', '温馨', '华丽',
];

/// 编辑结果
class EditResult {
  final String newText;
  final String mode;
  final bool hasSnapshot;

  const EditResult({
    required this.newText,
    required this.mode,
    this.hasSnapshot = false,
  });
}

abstract class IRetroactiveEditService {
  /// 对选中文本执行编辑
  Future<EditResult> edit({
    required String selectedText,
    required String fullContext,
    required EditMode mode,
    String? targetTone,
    int? startOffset,
    int? endOffset,
  });

  /// 撤销上一次编辑
  Future<String?> undo(String documentId);

  /// 获取编辑历史
  List<String> getHistory(String documentId);
}
