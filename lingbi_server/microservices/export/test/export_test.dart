import 'dart:convert';
import '../lib/export_service.dart';
import 'package:test/test.dart';

void main() {
  group('ExportService', () {
    late ExportService service;

    setUp(() {
      service = ExportService();
    });

    group('Markdown export', () {
      test('should export valid markdown with correct filename', () async {
        final result = await service.export('Hello world', 'MyDoc', 'markdown');
        expect(result['success'], true);
        expect(result['format'], 'markdown');
        expect(result['filename'], 'MyDoc.md');
      });

      test('should include title as H1 in markdown content', () async {
        final result =
            await service.export('Some content', 'Title', 'markdown');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, startsWith('# Title'));
        expect(decoded, contains('Some content'));
      });

      test('should report correct byte size for markdown', () async {
        final result = await service.export('A', 'T', 'markdown');
        expect(result['size'], isA<int>());
        expect(result['size'], greaterThan(0));
      });
    });

    group('TXT export', () {
      test('should export valid plain text with correct filename', () async {
        final result = await service.export('Hello', 'Doc', 'txt');
        expect(result['success'], true);
        expect(result['format'], 'txt');
        expect(result['filename'], 'Doc.txt');
      });

      test('should strip markdown syntax in txt export', () async {
        final result =
            await service.export('**bold** and *italic*', 'Test', 'txt');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, isNot(contains('**')));
        expect(decoded, contains('bold'));
        expect(decoded, contains('italic'));
      });

      test('should include a plain-text title header in txt export', () async {
        final result = await service.export('body', 'MyTitle', 'txt');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, startsWith('MyTitle'));
        expect(decoded, contains('body'));
      });
    });

    group('PDF export', () {
      test('should export with correct filename and format', () async {
        final result = await service.export('Content', 'Doc', 'pdf');
        expect(result['success'], true);
        expect(result['format'], 'pdf');
        expect(result['filename'], 'Doc.pdf');
      });

      test('should generate HTML content inside PDF export', () async {
        final result = await service.export('Hello', 'Doc', 'pdf');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, contains('<!DOCTYPE html>'));
        expect(decoded, contains('<h1>Doc</h1>'));
        expect(decoded, contains('Hello'));
      });

      test('should include a mock note for PDF export', () async {
        final result = await service.export('X', 'Y', 'pdf');
        expect(result['note'], isA<String>());
        expect(result['note'], contains('Mock'));
      });
    });

    group('Input validation', () {
      test('should reject empty content', () async {
        final result = await service.export('', 'Title', 'markdown');
        expect(result['success'], false);
        expect(result['error'], contains('Content cannot be empty'));
      });

      test('should reject empty title', () async {
        final result = await service.export('Content', '', 'txt');
        expect(result['success'], false);
        expect(result['error'], contains('Title cannot be empty'));
      });

      test('should reject unsupported format', () async {
        final result = await service.export('Content', 'Title', 'docx');
        expect(result['success'], false);
        expect(result['error'], contains('Unsupported format'));
      });
    });

    group('Supported formats', () {
      test('should list supported formats', () {
        expect(service.supportedFormats, contains('markdown'));
        expect(service.supportedFormats, contains('txt'));
        expect(service.supportedFormats, contains('pdf'));
        expect(service.supportedFormats.length, 3);
      });
    });

    group('Markdown stripping', () {
      test('should strip code blocks from markdown', () async {
        final result = await service.export(
            'Text with ```code block``` inside', 'T', 'txt');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, isNot(contains('```')));
      });

      test('should strip links from markdown', () async {
        final result = await service.export(
            'A [link](http://example.com) here', 'T', 'txt');
        final decoded = utf8.decode(base64Decode(result['content'] as String));
        expect(decoded, contains('link'));
        expect(decoded, isNot(contains('http://')));
      });
    });
  });
}
