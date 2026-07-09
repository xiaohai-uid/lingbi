import 'package:flutter/material.dart';

import 'package:lingbi/core/models/character_edge.dart';

/// 角色关系图谱视图
///
/// 以简单力导向布局渲染 [characters] 为节点、[edges] 为关系边。
/// 支持点击节点高亮其关系，并通过 [onAddEdge] 回调新增关系（内存态）。
class CharacterGraphView extends StatefulWidget {
  const CharacterGraphView({
    super.key,
    required this.characters,
    this.edges = const [],
    this.onAddEdge,
  });
  final List<CharacterLike> characters;
  final List<CharacterEdge> edges;
  final void Function(String sourceId, String targetId, RelationshipType type)?
      onAddEdge;

  @override
  State<CharacterGraphView> createState() => _CharacterGraphViewState();
}

/// 图谱使用的轻量角色表示
class CharacterLike {
  const CharacterLike({required this.id, required this.name, this.role = ''});
  final String id;
  final String name;
  final String role;
}

class _CharacterGraphViewState extends State<CharacterGraphView> {
  String? _selectedId;
  final Map<String, Offset> _positions = {};

  @override
  void didUpdateWidget(covariant CharacterGraphView old) {
    super.didUpdateWidget(old);
    if (old.characters != widget.characters) _layout();
  }

  @override
  void initState() {
    super.initState();
    _layout();
  }

  void _layout() {
    _positions.clear();
    final n = widget.characters.length;
    if (n == 0) return;
    const radius = 160.0;
    final center = const Offset(220, 200);
    for (var i = 0; i < n; i++) {
      final c = widget.characters[i];
      final dx = radius * (n == 1 ? 0 : 0.85 * (i.isEven ? 1 : -1));
      final dy = radius * 0.8 * (i.isOdd ? 1 : -1) * (i == 0 ? 0 : 1);
      _positions[c.id] = Offset(center.dx + dx, center.dy + dy);
    }
  }

  Color _nodeColor(String role) {
    if (role == '主角') return const Color(0xFF4CAF50);
    if (role == '反派') return const Color(0xFFF44336);
    if (role == '配角') return const Color(0xFF2196F3);
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.characters.isEmpty) {
      return const Center(child: Text('暂无角色，请先在「角色」标签页创建'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.hub, size: 18),
              const SizedBox(width: 8),
              Text('角色关系图谱（${widget.characters.length} 角色 / ${widget.edges.length} 关系）',
                  style: theme.textTheme.labelMedium),
              const Spacer(),
              if (widget.onAddEdge != null)
                TextButton.icon(
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text('添加关系'),
                  onPressed: _showAddEdgeDialog,
                ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 2.5,
            child: CustomPaint(
              size: const Size(440, 400),
              painter: _GraphPainter(
                characters: widget.characters,
                edges: widget.edges,
                positions: _positions,
                selectedId: _selectedId,
                nodeColor: _nodeColor,
              ),
              child: GestureDetector(
                onTapUp: _onTap,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onTap(TapUpDetails details) {
    final p = details.localPosition;
    String? hit;
    for (final c in widget.characters) {
      final pos = _positions[c.id];
      if (pos != null && (pos - p).distance < 26) {
        hit = c.id;
        break;
      }
    }
    setState(() => _selectedId = hit);
  }

  void _showAddEdgeDialog() {
    CharacterLike? source = widget.characters.isEmpty ? null : widget.characters.first;
    CharacterLike? target = widget.characters.length > 1 ? widget.characters[1] : null;
    var type = RelationshipType.neutral;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('添加角色关系'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CharacterLike>(
                value: source,
                items: widget.characters
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setSt(() => source = v),
                decoration: const InputDecoration(labelText: '源角色'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CharacterLike>(
                value: target,
                items: widget.characters
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setSt(() => target = v),
                decoration: const InputDecoration(labelText: '目标角色'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<RelationshipType>(
                value: type,
                items: RelationshipType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                    .toList(),
                onChanged: (v) => setSt(() => type = v ?? RelationshipType.neutral),
                decoration: const InputDecoration(labelText: '关系类型'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (source != null && target != null && source!.id != target!.id) {
                  widget.onAddEdge?.call(source!.id, target!.id, type);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.characters,
    required this.edges,
    required this.positions,
    required this.selectedId,
    required this.nodeColor,
  });
  final List<CharacterLike> characters;
  final List<CharacterEdge> edges;
  final Map<String, Offset> positions;
  final String? selectedId;
  final Color Function(String) nodeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;
    for (final e in edges) {
      final a = positions[e.sourceId];
      final b = positions[e.targetId];
      if (a == null || b == null) continue;
      final active = selectedId == e.sourceId || selectedId == e.targetId;
      edgePaint.color = active ? Colors.orange : Colors.grey.withValues(alpha: 0.5);
      canvas.drawLine(a, b, edgePaint);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: e.type.displayName,
          style: TextStyle(fontSize: 11, color: active ? Colors.orange : Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
    }
    for (final c in characters) {
      final pos = positions[c.id];
      if (pos == null) continue;
      final selected = selectedId == c.id;
      final r = selected ? 22.0 : 18.0;
      canvas.drawCircle(pos, r, Paint()..color = nodeColor(c.role));
      if (selected) {
        canvas.drawCircle(
          pos,
          r + 4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.orange,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: c.name,
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.characters != characters ||
      old.edges != edges ||
      old.positions != positions ||
      old.selectedId != selectedId;
}
