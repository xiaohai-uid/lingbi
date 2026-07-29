import 'package:flutter/material.dart';
import 'package:lingbi/shared/models/document.dart';
import '../theme/tokens.dart';

/// Project-scoped document search results used by the top-bar search action.
class DocumentSearchDialog extends StatelessWidget {
  const DocumentSearchDialog({
    super.key,
    required this.query,
    required this.results,
    required this.onSelected,
  });

  final String query;
  final List<Document> results;
  final ValueChanged<Document> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = LingBiColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(LingBiTokens.radiusLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 460),
        child: Padding(
          padding: const EdgeInsets.all(LingBiTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('搜索结果', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: LingBiTokens.space1),
              Text(
                '「$query」 · ${results.length} 个文档',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: LingBiTokens.space3),
              if (results.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: LingBiTokens.space8),
                  child: Center(
                    child: Text('没有找到匹配的文档',
                        style: TextStyle(color: colors.muted)),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: LingBiTokens.space1),
                    itemBuilder: (context, index) {
                      final document = results[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.description_outlined,
                            color: colors.accent),
                        title: Text(document.title,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(document.filePath,
                            overflow: TextOverflow.ellipsis),
                        onTap: () => onSelected(document),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
