/// 审批流面板 - 管理小说创作中的审批流程
library;

import 'package:flutter/material.dart';
import 'package:lingbi/shared/di/service_locator.dart';
import 'package:lingbi/services/workflow_approval_service.dart';

class WorkflowApprovalPanel extends StatefulWidget {
  const WorkflowApprovalPanel({super.key, required this.projectId});

  final String projectId;

  @override
  State<WorkflowApprovalPanel> createState() => _WorkflowApprovalPanelState();
}

class _WorkflowApprovalPanelState extends State<WorkflowApprovalPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  List<ApprovalRecord> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ApprovalRecord> get _pendingItems =>
      _allRecords.where((r) => r.status == ApprovalStatus.pending).toList();
  List<ApprovalRecord> get _approvedItems =>
      _allRecords.where((r) => r.status == ApprovalStatus.approved).toList();
  List<ApprovalRecord> get _rejectedItems =>
      _allRecords.where((r) => r.status == ApprovalStatus.rejected).toList();

  Future<void> _load() async {
    try {
      final records = await ServiceLocator.instance.workflowApprovalService
          .listRecords(widget.projectId);
      if (mounted) {
        setState(() {
          _allRecords = records;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approveItem(ApprovalRecord record) async {
    await ServiceLocator.instance.workflowApprovalService
        .approve(widget.projectId, record.targetId);
    await _load();
  }

  Future<void> _rejectItem(ApprovalRecord record) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拒绝审批'),
        content: TextField(
          controller: feedbackController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '修改意见（必填）',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认拒绝'),
          ),
        ],
      ),
    );

    if (confirmed == true && feedbackController.text.trim().isNotEmpty) {
      await ServiceLocator.instance.workflowApprovalService.reject(
        widget.projectId,
        record.targetId,
        feedback: feedbackController.text.trim(),
      );
      await _load();
    }
  }

  Future<void> _submitApproval() async {
    final targetController = TextEditingController();
    final contentController = TextEditingController();
    String selectedType = ApprovalTargetType.chapter.name;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('提交审批'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: '目标标识',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: '类型',
                    border: OutlineInputBorder(),
                  ),
                  items: ApprovalTargetType.values
                      .map((t) => DropdownMenuItem(
                          value: t.name, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );

    if (result == true && targetController.text.trim().isNotEmpty) {
      await ServiceLocator.instance.workflowApprovalService.createRecord(
        projectId: widget.projectId,
        targetId: targetController.text.trim(),
        targetType: ApprovalTargetType.fromString(selectedType),
        content: contentController.text.trim(),
      );
      // 自动提交审批
      await ServiceLocator.instance.workflowApprovalService
          .submitForReview(widget.projectId, targetController.text.trim());
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: '待审批 (${_pendingItems.length})'),
                Tab(text: '已通过 (${_approvedItems.length})'),
                Tab(text: '已拒绝 (${_rejectedItems.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildApprovalList(_pendingItems, isPending: true),
                  _buildApprovalList(_approvedItems, isPending: false),
                  _buildApprovalList(_rejectedItems, isPending: false),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _submitApproval,
            tooltip: '提交审批',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalList(List<ApprovalRecord> items,
      {required bool isPending}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('暂无内容',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          items.map((item) => _buildItemCard(item, isPending: isPending)).toList(),
    );
  }

  Widget _buildItemCard(ApprovalRecord item, {required bool isPending}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.targetType.label}: ${item.targetId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildStatusChip(item.status),
              ],
            ),
            const SizedBox(height: 8),
            if (item.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            if (item.feedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('意见: ${item.feedback}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13)),
              ),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text(item.createdAt.substring(0, 16),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (isPending) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _rejectItem(item),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('拒绝'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _approveItem(item),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('通过'),
                  ),
                ],
              ),
            ],
            if (!isPending && item.history.isNotEmpty) ...[
              const Divider(),
              _buildHistoryTimeline(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ApprovalStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(ApprovalStatus status) {
    return switch (status) {
      ApprovalStatus.draft => Colors.grey,
      ApprovalStatus.pending => Colors.orange,
      ApprovalStatus.approved => Colors.green,
      ApprovalStatus.rejected => Colors.red,
    };
  }

  Widget _buildHistoryTimeline(ApprovalRecord item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('审批记录',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        ...item.history.map((entry) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColor(entry.action),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.action.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500),
                        ),
                        if (entry.feedback.isNotEmpty)
                          Text(entry.feedback,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                        Text(
                          entry.timestamp.substring(0, 16),
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
