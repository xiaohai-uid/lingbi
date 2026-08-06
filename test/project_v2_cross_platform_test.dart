import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/project/data/project_service.dart';
import 'package:lingbi/shared/file_system/file_service.dart';

const crossFixture = String.fromEnvironment('LINGBI_V2_CROSS_FIXTURE');

void main() {
  test('Flutter reopens fixture after Rust edit', () async {
    final proofFile =
        File('$crossFixture/.lingbi/cross-platform-proof.json');
    expect(proofFile.existsSync(), isTrue,
        reason: 'Rust cross-platform edit must write proof metadata');

    final proof =
        jsonDecode(await proofFile.readAsString()) as Map<String, dynamic>;
    final service = ProjectService(fileService: FileService());
    final opened = await service.openPortableProject(crossFixture);
    expect(opened.project.id, proof['project_id']);
    expect(opened.project.name, proof['project_name']);
    final document = opened.documents.singleWhere(
      (document) => document.id == proof['document_id'],
    );

    expect(document.revision, proof['revision']);
    expect(document.contentHash, proof['content_hash']);
    expect(
      await File(document.filePath).readAsString(),
      proof['expected_content'],
    );
  }, skip: crossFixture.isEmpty ? 'LINGBI_V2_CROSS_FIXTURE 未设置' : false);
}
