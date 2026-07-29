import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/version_history_service.dart';
import '../theme/tokens.dart';
import '../theme/lingbi_icons.dart';

class VersionHistoryPage extends StatefulWidget {

  const VersionHistoryPage({
    super.key,
    this.projectId,
    this.projectDir,
    this.docId,
  });
  final String? projectId;
  final String? projectDir;
  final String? docId;

  @override
  State<VersionHistoryPage> createState() => _VersionHistoryPageState();
}

class _VersionHistoryPageState extends State<VersionHistoryPage> {
  List<VersionInfo> _versions = [];
  VersionInfo? _selectedVersion;
  String? _previewContent;
  bool _loading = false;
  bool _loadingPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectDir != null && widget.docId != null) _loadData();
  }

  @override
  void didUpdateWidget(covariant VersionHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projectDir != oldWidget.projectDir ||
        widget.docId != oldWidget.docId) {
      if (widget.projectDir != null && widget.docId != null) _loadData();
    }
  }

  Future<void> _loadData() async {
    final dir = widget.projectDir;
    final docId = widget.docId;
    if (dir == null || docId == null) return;
    setState(() => _loading = true);
    try {
      final versions = await ServiceLocator.instance.versionHistoryService
          .getVersions(projectDir: dir, docId: docId);
      if (mounted) {
        setState(() {
          _versions = versions;
          _selectedVersion = null;
          _previewContent = null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectVersion(VersionInfo v) async {
    final dir = widget.projectDir;
    final docId = widget.docId;
    if (dir == null || docId == null) return;
    setState(() {
      _selectedVersion = v;
      _loadingPreview = true;
      _previewContent = null;
    });
    try {
      final content = await ServiceLocator.instance.versionHistoryService
          .getVersionContent(
        projectDir: dir,
        docId: docId,
        versionId: v.id,
      );
      if (mounted) {
        setState(() {
          _previewContent = content ?? '（内容不可用）';
          _loadingPreview = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _previewContent = '（加载失败）';
          _loadingPreview = false;
        });
      }
    }
  }

  String _formatDate(DateTime dt) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
        '${pad(dt.hour)}:${pad(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = LingBiColors.of(context);
    return Column(
      children: [
        _buildHeader(c),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: _buildTimeline(c),
                    ),
                    Container(
                      width: 1,
                      color: c.borderOpaque.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildPreview(c),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(LingBiColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        LingBiTokens.space5,
        LingBiTokens.space6,
        LingBiTokens.space3,
      ),
      child: Row(
        children: [
          Text(
            '版本历史',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: c.fg,
              letterSpacing: -0.625 / 26 * 26,
            ),
          ),
          const Spacer(),
          Text(
            _versions.isNotEmpty
                ? '当前版本：${_versions.first.id}'
                : '当前版本：无',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(LingBiColors c) {
    if (_versions.isEmpty) {
      return Center(
        child: Text(
          '暂无版本历史',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        LingBiTokens.space6,
        0,
        LingBiTokens.space6,
        LingBiTokens.space6,
      ),
      itemCount: _versions.length,
      itemBuilder: (context, index) => _buildVersionItem(
        _versions[index],
        index,
        _versions.length,
        c,
      ),
    );
  }

  Widget _buildVersionItem(
    VersionInfo v,
    int index,
    int total,
    LingBiColors c,
  ) {
    final isLast = index == total - 1;
    final isCurrent = index == 0;
    final isSelected = _selectedVersion?.id == v.id;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCurrent ? c.accent : c.borderOpaque,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                            color: c.accent.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: c.borderOpaque.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: LingBiTokens.space3),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: () => _selectVersion(v),
              child: Container(
                margin:
                    EdgeInsets.only(bottom: isLast ? 0 : LingBiTokens.space4),
                padding: const EdgeInsets.all(LingBiTokens.space4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? c.accent.withValues(alpha: 0.08)
                      : isCurrent
                          ? c.accent.withValues(alpha: 0.04)
                          : c.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
                  border: Border.all(
                    color: isSelected
                        ? c.accent.withValues(alpha: 0.4)
                        : isCurrent
                            ? c.accent.withValues(alpha: 0.15)
                            : c.borderOpaque.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                v.id,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: c.fg,
                                ),
                              ),
                              if (v.summary.isNotEmpty) ...[
                                const SizedBox(width: LingBiTokens.space2),
                                _buildTag(c, v.summary),
                              ],
                            ],
                          ),
                          const SizedBox(height: LingBiTokens.space1),
                          Text(
                            '${v.wordCount} 字',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: c.fgSecondary,
                            ),
                          ),
                          const SizedBox(height: LingBiTokens.space1),
                          Text(
                            _formatDate(v.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        '当前',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.accent,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _iconButton(LingBiIcons.restore, c,
                              () => _selectVersion(v)),
                          const SizedBox(width: LingBiTokens.space1),
                          _iconButton(LingBiIcons.more, c, () {}),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(LingBiColors c, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LingBiTokens.radiusPill),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: c.accent,
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, LingBiColors c, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LingBiTokens.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(LingBiTokens.space1),
          child: Icon(icon, size: 16, color: c.fgSecondary),
        ),
      ),
    );
  }

  Widget _buildPreview(LingBiColors c) {
    final selected = _selectedVersion;
    return Padding(
      padding: const EdgeInsets.all(LingBiTokens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected != null ? '预览：${selected.id}' : '选择一个版本预览',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.fg,
            ),
          ),
          const SizedBox(height: LingBiTokens.space4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(LingBiTokens.space4),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
                border: Border.all(
                  color: c.borderOpaque.withValues(alpha: 0.4),
                ),
              ),
              child: _buildPreviewContent(c),
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: LingBiTokens.space4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _selectedVersion = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.fgSecondary,
                    side: BorderSide(color: c.borderOpaque),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusSm),
                    ),
                  ),
                  child: const Text('取消'),
                ),
                const SizedBox(width: LingBiTokens.space2),
                ElevatedButton(
                  onPressed: () async {
                    final dir = widget.projectDir;
                    final docId = widget.docId;
                    if (dir == null || docId == null) return;
                    try {
                      await ServiceLocator
                          .instance.versionHistoryService
                          .restoreVersion(
                        projectDir: dir,
                        docId: docId,
                        versionId: selected.id,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已恢复到版本 ${selected.id}')),
                        );
                        await _loadData();
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('恢复失败')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(LingBiTokens.radiusSm),
                    ),
                  ),
                  child: const Text('恢复到此版本'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewContent(LingBiColors c) {
    if (_selectedVersion == null) {
      return Center(
        child: Text(
          '点击左侧版本查看预览',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      );
    }
    if (_loadingPreview) {
      return const Center(child: CircularProgressIndicator());
    }
    final content = _previewContent;
    if (content == null) {
      return Center(
        child: Text(
          '（内容不可用）',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      );
    }
    return SingleChildScrollView(
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: c.fg,
          height: 1.8,
        ),
      ),
    );
  }
}
