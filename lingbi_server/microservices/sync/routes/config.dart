import 'package:dart_frog/dart_frog.dart';
import '../lib/sync_service.dart';

RequestHandler config(Request request) async {
  try {
    final body = await request.json();
    final key = body['key'];
    final value = body['value'];

    if (key == null) {
      // If no key provided, return all config
      final allConfig = await syncService.getConfig();
      return Response(
        body: jsonEncode(allConfig),
        headers: {'Content-Type': 'application/json'},
        statusCode: 200,
      );
    }

    if (value == null) {
      return Response(
        body: jsonEncode({'error': 'value is required when setting config'}),
        headers: {'Content-Type': 'application/json'},
        statusCode: 400,
      );
    }

    await syncService.setConfig(key, value);

    return Response(
      body: jsonEncode({
        'status': 'config_updated',
        'key': key,
        'value': value,
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
