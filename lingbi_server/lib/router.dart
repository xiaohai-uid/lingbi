import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

import 'package:lingbi_server/proxy.dart';

/// Build a dart_frog [Router] that proxies all /api/v1/* requests to
/// the appropriate microservice.
Router buildRouter({http.Client? httpClient}) {
  final router = Router();
  final client = httpClient ?? http.Client();

  for (final config in microservices) {
    // Wildcard pattern: match any path after the prefix
    router.all(
      '${config.pathPrefix}/<__path|[^]*>',
      (RequestContext context, String path) async {
        final fullPath = '${config.pathPrefix}/$path';
        final method = context.request.method.value;
        final query = context.request.uri.query;
        final request = http.Request(method, Uri(path: fullPath, query: query));
        context.request.headers.forEach(
          (name, value) => request.headers[name] = value,
        );
        final response = await proxyToPort(request, config.port, client);
        return Response.stream(
          statusCode: response.statusCode,
          headers: response.headers,
          body: response.stream.cast<List<int>>(),
        );
      },
    );
  }

  return router;
}
