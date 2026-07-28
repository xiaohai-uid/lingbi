import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/core/models/document.dart';
import 'package:lingbi/ui_v2/components/document_search_dialog.dart';

void main() {
  testWidgets('search dialog exposes matching documents and selection',
      (tester) async {
    final document = Document(
      projectId: 'p1',
      title: '开场设计',
      filePath: '开场设计.md',
    );
    Document? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DocumentSearchDialog(
          query: '开场',
          results: [document],
          onSelected: (value) => selected = value,
        ),
      ),
    ));

    expect(find.text('搜索结果'), findsOneWidget);
    expect(find.text('开场设计'), findsOneWidget);
    await tester.tap(find.text('开场设计'));
    expect(selected, same(document));
  });
}
