import 'package:dart_frog/dart_frog.dart';
import '../lib/sync_service.dart';

RequestHandler status(Request request) async {
  try {
    final status = syncService.getStatus();

    return Response(
      body: jsonEncode(status),
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