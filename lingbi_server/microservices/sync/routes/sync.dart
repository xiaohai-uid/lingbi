import 'package:dart_frog/dart_frog.dart';
import '../lib/sync_service.dart';

RequestHandler sync(Request request) async {
  try {
    final body = await request.json();
    final sourcePath = body['source_path'];
    final destPath = body['dest_path'];

    if (sourcePath == null || destPath == null) {
      return Response(
        body: jsonEncode({'error': 'source_path and dest_path are required'}),
        headers: {'Content-Type': 'application/json'},
        statusCode: 400,
      );
    }

    await syncService.startSync(sourcePath, destPath);

    return Response(
      body: jsonEncode({
        'status': 'sync_started',
        'source_path': sourcePath,
        'dest_path': destPath,
      }),
      headers: {'Content-Type': 'application/json'},
      statusCode: 200,
    );
  } catch (e) {
    return Response(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
      statusCode: 500,
    );
  }
}
