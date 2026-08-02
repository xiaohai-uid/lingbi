/// 题材种子数据 — 新建项目时按 genreId 预填的创作资料骨架。
///
/// 每个题材提供 `小说资料/世界观.md` 与 `小说资料/人物库.md` 的初始骨架，
/// 路径与 NovelWritingLoop 读取的设定目录一致，确保"打开即有用"，
/// 并作为后续引导流程 / AI 续写的 mandatory 上下文。
library;

/// 单个题材的种子骨架。
class GenreSeedData {
  const GenreSeedData({
    required this.genreId,
    required this.genreLabel,
    required this.worldbuildingMarkdown,
    required this.charactersMarkdown,
  });

  /// 题材 ID（与 ProjectTemplate.genreId 一致，如 `xuanhuan`）。
  final String genreId;

  /// 题材中文名（用于展示）。
  final String genreLabel;

  /// `小说资料/世界观.md` 初始内容。
  final String worldbuildingMarkdown;

  /// `小说资料/人物库.md` 初始内容。
  final String charactersMarkdown;
}

/// 按 genreId 索引的题材种子表。
///
/// 未收录的 genreId（如自由创作 `''`）返回 null，创建时不播种。
const Map<String, GenreSeedData> genreSeedTable = {
  'xuanhuan': GenreSeedData(
    genreId: 'xuanhuan',
    genreLabel: '玄幻',
    worldbuildingMarkdown: '''
# 世界观（玄幻）

> 这是由「玄幻」模板预填的骨架，括号内为待完善提示，可在右侧 AI 助手引导中逐步补全。

## 修炼体系
- 境界划分：（待完善，如 炼体 → 灵动 → 金丹 → 元婴 → 化神 …）
- 突破条件：（待完善：机缘 / 丹药 / 悟道 / 渡劫）
- 修炼资源：（待完善：灵石 / 灵脉 / 天材地宝）
- 力量上限与代价：（待完善）

## 势力格局
- 顶级宗门：（待完善）
- 世俗王朝：（待完善）
- 核心矛盾：（待完善：正邪 / 宗门倾轧 / 天地大劫）

## 地理种族
- 世界结构：（待完善：九州 / 三千大世界 / 位面）
- 主要地域：（待完善）
- 种族设定：（待完善：人族 / 妖族 / 古族）

## 核心设定（金手指）
- 主角依仗：（待完善：功法 / 神器 / 系统 / 血脉）
''',
    charactersMarkdown: '''
# 人物库（玄幻）

## 主角
- 姓名：（待定）
- 出身：（待定：废柴逆袭 / 世家子弟 / 重生）
- 金手指：（待定）
- 起始境界：（待定）
- 核心驱动力：（待定：复仇 / 长生 / 守护）

## 重要配角
- 姓名 / 关系：（待定）
- 作用：（待定：引路人 / 红颜 / 兄弟）

## 初期反派
- 姓名：（待定）
- 压迫感来源：（待定：境界碾压 / 势力背景）
- 与主角的冲突点：（待定）
''',
  ),
  'urban': GenreSeedData(
    genreId: 'urban',
    genreLabel: '都市',
    worldbuildingMarkdown: '''
# 世界观（都市）

## 时代背景
- 城市 / 年代：（待完善）
- 行业舞台：（待完善：职场 / 商战 / 医道 / 兵王回归）

## 格局势力
- 公司 / 家族：（待完善）
- 对手阵营：（待完善）

## 金手指
- 主角依仗：（待完善：系统 / 异能 / 重生记忆 / 绝世医术）

## 爽点节奏
- 主线目标：（待完善）
- 阶段性打脸对象：（待完善）
''',
    charactersMarkdown: '''
# 人物库（都市）

## 主角
- 姓名：（待定）
- 身份反差：（待定：表面平凡 / 实则…）
- 金手指：（待定）
- 核心驱动力：（待定）

## 重要配角
- 姓名 / 关系：（待定）

## 反派
- 姓名 / 势力：（待定）
- 冲突点：（待定）
''',
  ),
  'suspense': GenreSeedData(
    genreId: 'suspense',
    genreLabel: '悬疑',
    worldbuildingMarkdown: '''
# 世界观（悬疑）

## 核心谜题
- 中心案件 / 谜面：（待完善）
- 真相轮廓（仅作者知）：（待完善）

## 线索布局
- 明线：（待完善）
- 暗线 / 误导项：（待完善）

## 叙事诡计
- 视角 / 时间诡计：（待完善）
- 反转设计：（待完善）

## 场景
- 主要场景：（待完善：密室 / 孤岛 / 小镇）
''',
    charactersMarkdown: '''
# 人物库（悬疑）

## 主角（侦探 / 当事人）
- 姓名：（待定）
- 动机：（待定）
- 隐藏秘密：（待定）

## 嫌疑人
- 姓名 / 表面身份：（待定）
- 真实角色（仅作者知）：（待定）

## 受害者
- 姓名 / 关系网：（待定）
''',
  ),
  'romance': GenreSeedData(
    genreId: 'romance',
    genreLabel: '言情',
    worldbuildingMarkdown: '''
# 世界观（言情）

## 背景设定
- 时代 / 圈层：（待完善：现代都市 / 古代宅斗 / 娱乐圈 / 校园）

## 情感主线
- 男女主关系起点：（待完善）
- 核心阻碍：（待完善）
- 情感推进节点：（待完善）

## 情绪基调
- 风格：（待完善：甜宠 / 虐恋 / 先婚后爱 / 破镜重圆）
''',
    charactersMarkdown: '''
# 人物库（言情）

## 女主
- 姓名 / 性格：（待定）
- 人物弧光：（待定）

## 男主
- 姓名 / 性格：（待定）
- 人物弧光：（待定）

## 关键配角
- 情敌 / 助攻：（待定）
''',
  ),
  'scifi': GenreSeedData(
    genreId: 'scifi',
    genreLabel: '科幻',
    worldbuildingMarkdown: '''
# 世界观（科幻）

## 科技设定
- 核心科技：（待完善：星际航行 / 人工智能 / 基因改造）
- 科技边界与代价：（待完善）

## 世界规则
- 社会形态：（待完善）
- 宇宙 / 文明格局：（待完善）

## 硬核逻辑
- 核心冲突的科学依据：（待完善）
- 设定自洽约束：（待完善）
''',
    charactersMarkdown: '''
# 人物库（科幻）

## 主角
- 姓名 / 职业：（待定）
- 核心驱动力：（待定）

## 重要配角
- 姓名 / 关系：（待定）

## 对立力量
- 反派 / 危机来源：（待定）
''',
  ),
  'history': GenreSeedData(
    genreId: 'history',
    genreLabel: '历史',
    worldbuildingMarkdown: '''
# 世界观（历史）

## 时代背景
- 朝代 / 年代：（待完善）
- 真实历史坐标：（待完善）

## 势力沿革
- 朝廷 / 派系：（待完善）
- 地方 / 外族：（待完善）

## 史实与虚构边界
- 采用的史实：（待完善）
- 虚构演绎部分：（待完善）

## 主角立场
- 身份与阵营：（待完善）
''',
    charactersMarkdown: '''
# 人物库（历史）

## 主角
- 姓名 / 身份：（待定）
- 历史原型（如有）：（待定）
- 核心驱动力：（待定）

## 历史人物
- 姓名 / 立场：（待定）

## 虚构人物
- 姓名 / 作用：（待定）
''',
  ),
};
