import 'package:dart_frog/dart_frog.dart';
import '../lib/export_service.dart';
import '../main.dart';

/// POST /export/txt — Export content as plain text
RequestHandler exportTxt(Request request) async {
  try {
    final body = await request.json();

    final content = body['content'] as String? ?? '';
    final title = body['title'] as String? ?? 'untitled';

    final result = await exportService.export(content, title, 'txt');

    final statusCode = result['success'] == true ? 200 : 400;
    return Response(
      body: jsonEncode(result),
      headers: {'Content-Type': 'application/json'},
      statusCode: statusCode,
    );
  } catch (e) {
    return Response(
      body: jsonEncode({'success': false, 'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
      statusCode: 500,
    );
  }
}
