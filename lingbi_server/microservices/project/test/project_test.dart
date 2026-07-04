import 'dart:io';

import 'package:project/models/project.dart';
import 'package:project/project_service.dart';
import 'package:test/test.dart';

void main() {
  // -------------------------------------------------------------------------
  // Project model tests
  // -------------------------------------------------------------------------
  group('Project model', () {
    test('should create a project with default values', () {
      final project = Project(id: 'p1', name: 'Test Project');

      expect(project.id, 'p1');
      expect(project.name, 'Test Project');
      expect(project.description, '');
      expect(project.documentCount, 0);
      expect(project.treeStructure, isEmpty);
      expect(project.createdAt, isNotNull);
      expect(project.updatedAt, isNotNull);
    });

    test('toJson and fromJson should round-trip', () {
      final original = Project(
        id: 'p-roundtrip-1',
        name: 'Round Trip',
        description: 'Test description',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 6, 15),
        documentCount: 5,
        treeStructure: {
          '_root': ['doc-1', 'doc-2'],
          'chapter-1': ['doc-3'],
        },
      );

      final json = original.toJson();
      final reconstructed = Project.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.description, original.description);
      expect(reconstructed.createdAt, original.createdAt);
      expect(reconstructed.updatedAt, original.updatedAt);
      expect(reconstructed.documentCount, original.documentCount);
      expect(reconstructed.treeStructure['_root'], ['doc-1', 'doc-2']);
      expect(reconstructed.treeStructure['chapter-1'], ['doc-3']);
    });

    test('copyWith should update only specified fields', () {
      final project = Project(
        id: 'p-copy-1',
        name: 'Original Name',
        description: 'Original desc',
      );

      final updated = project.copyWith(name: 'New Name');

      expect(updated.id, 'p-copy-1');
      expect(updated.name, 'New Name');
      expect(updated.description, 'Original desc');
    });

    test('equality should be based on id', () {
      final a = Project(id: 'eq-1', name: 'A');
      final b = Project(id: 'eq-1', name: 'B');
      final c = Project(id: 'eq-2', name: 'A');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // -------------------------------------------------------------------------
  // ProjectService tests
  // -------------------------------------------------------------------------
  group('ProjectService', () {
    late ProjectService service;
    final testDataDir = 'data/test_project_service';

    setUp(() async {
      // Clean up any previous test data
      final dir = Directory(testDataDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }

      service = ProjectService(dataPath: testDataDir);
      await service.initialize();
    });

    tearDown(() {
      service.close();
      final dir = Directory(testDataDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    // ---- CRUD ----

    test('should create and retrieve a project', () {
      final project = service.createProject(
        name: 'My Novel',
        description: 'A great story',
      );

      expect(project.id, isNotNull);
      expect(project.name, 'My Novel');
      expect(project.description, 'A great story');
      expect(project.documentCount, 0);

      final retrieved = service.getProjectById(project.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'My Novel');
    });

    test('should return null for non-existent project', () {
      final retrieved = service.getProjectById('non-existent-id');
      expect(retrieved, isNull);
    });

    test('should list all projects', () {
      service.createProject(name: 'Project A');
      service.createProject(name: 'Project B');
      service.createProject(name: 'Project C');

      final projects = service.listProjects();
      expect(projects.length, 3);
    });

    test('should update a project', () {
      final project = service.createProject(
        name: 'Original',
        description: 'Original desc',
      );

      final updated = service.updateProject(
        project.id,
        name: 'Updated Name',
        description: 'Updated desc',
      );

      expect(updated, isNotNull);
      expect(updated!.name, 'Updated Name');
      expect(updated.description, 'Updated desc');
    });

    test('should delete a project', () {
      final project = service.createProject(name: 'To Delete');

      expect(service.getProjectById(project.id), isNotNull);
      final deleted = service.deleteProject(project.id);
      expect(deleted, true);
      expect(service.getProjectById(project.id), isNull);

      // Delete non-existent returns false
      expect(service.deleteProject('non-existent'), false);
    });

    // ---- Tree structure ----

    test('should manage tree structure', () {
      final project = service.createProject(name: 'Tree Test');

      // Initial tree should be empty
      final initialTree = service.getTree(project.id);
      expect(initialTree, isEmpty);

      // Add document to root
      final added = service.addDocumentToTree(project.id, '_root', 'doc-1');
      expect(added, true);

      // Add document to a folder
      service.addDocumentToTree(project.id, 'chapter-1', 'doc-2');
      service.addDocumentToTree(project.id, 'chapter-1', 'doc-3');

      final tree = service.getTree(project.id)!;
      expect(tree['_root'], contains('doc-1'));
      expect(tree['chapter-1'], contains('doc-2'));
      expect(tree['chapter-1'], contains('doc-3'));

      // Remove document
      final removed = service.removeDocumentFromTree(project.id, 'doc-1');
      expect(removed, true);
      expect(service.getTree(project.id)!['_root'], isEmpty);

      // Move document
      service.moveDocumentInTree(project.id, 'doc-2', '_root');
      expect(service.getTree(project.id)!['_root'], contains('doc-2'));
      expect(service.getTree(project.id)!['chapter-1'], isNot(contains('doc-2')));

      // Update entire tree
      final newTree = {
        'folder-a': ['doc-a', 'doc-b'],
        'folder-b': ['doc-c'],
      };
      final updated = service.updateTree(project.id, newTree);
      expect(updated, true);
      expect(service.getTree(project.id)!['folder-a'], ['doc-a', 'doc-b']);
    });

    test('should return null tree for non-existent project', () {
      final tree = service.getTree('non-existent');
      expect(tree, isNull);
    });

    // ---- Persistence ----

    test('should persist data across re-initialization', () async {
      final project = service.createProject(
        name: 'Persist Test',
        description: 'Should survive restart',
      );
      service.addDocumentToTree(project.id, '_root', 'doc-x');

      // Re-initialize the service with same data path
      service.close();
      service = ProjectService(dataPath: testDataDir);
      await service.initialize();

      final retrieved = service.getProjectById(project.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Persist Test');
      expect(retrieved.treeStructure['_root'], contains('doc-x'));
    });

    // ---- Markdown import / export ----

    test('should import from Markdown files', () {
      // Create temp markdown files
      final tempDir = Directory('${testDataDir}_md');
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      tempDir.createSync(recursive: true);

      File('${tempDir.path}/chapter1.md').writeAsStringSync('# Chapter 1\nContent here.');
      File('${tempDir.path}/chapter2.md').writeAsStringSync('# Chapter 2\nMore content.');

      final filePaths = [
        '${tempDir.path}/chapter1.md',
        '${tempDir.path}/chapter2.md',
      ];

      final ids = service.importFromMarkdown(filePaths);
      expect(ids.length, 2);

      // Verify projects were created
      for (final id in ids) {
        final project = service.getProjectById(id);
        expect(project, isNotNull);
      }

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });

    test('should export project to Markdown', () {
      final project = service.createProject(
        name: 'Export Test',
        description: 'For export testing',
      );

      service.addDocumentToTree(project.id, '_root', 'intro');
      service.addDocumentToTree(project.id, 'chapters', 'ch-1');

      final outputDir = service.exportToMarkdown(project.id);
      expect(outputDir, isNotNull);

      // Check that index.md was created
      final indexFile = File('$outputDir/index.md');
      expect(indexFile.existsSync(), true);

      final content = indexFile.readAsStringSync();
      expect(content, contains('Export Test'));
      expect(content, contains('intro'));
      expect(content, contains('ch-1'));

      // Cleanup
      Directory(outputDir!).deleteSync(recursive: true);
    });

    test('should return null when exporting non-existent project', () {
      final result = service.exportToMarkdown('non-existent');
      expect(result, isNull);
    });
  });
}