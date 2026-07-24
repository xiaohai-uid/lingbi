import 'package:http/http.dart' as http;

/// Proxy configuration for each microservice.
class ProxyConfig {
  final String pathPrefix;
  final int port;

  const ProxyConfig(this.pathPrefix, this.port);
}

/// All 11 microservices and their port assignments.
const microservices = <ProxyConfig>[
  ProxyConfig('/api/v1/ai', 8081),
  ProxyConfig('/api/v1/project', 8082),
  ProxyConfig('/api/v1/document', 8083),
  ProxyConfig('/api/v1/canon', 8084),
  ProxyConfig('/api/v1/export', 8085),
  ProxyConfig('/api/v1/version', 8086),
  ProxyConfig('/api/v1/settings', 8087),
  ProxyConfig('/api/v1/quota', 8088),
  ProxyConfig('/api/v1/storage', 8089),
  ProxyConfig('/api/v1/sync', 8090),
  ProxyConfig('/api/v1/canvas', 8091),
];

/// Find which microservice a request should be proxied to.
ProxyConfig? routeToMicroservice(String uriPath) {
  for (final config in microservices) {
    if (uriPath.startsWith(config.pathPrefix)) {
      return config;
    }
  }
  return null;
}

/// Proxy an incoming request to the given port on localhost.
Future<http.StreamedResponse> proxyToPort(
  http.BaseRequest request,
  int port,
  http.Client client,
) async {
  final uri = Uri(
    scheme: 'http',
    host: 'localhost',
    port: port,
    path: request.url.path,
    query: request.url.query,
  );

  final proxyReq = http.Request(request.method, uri);
  request.headers.forEach((name, value) => proxyReq.headers[name] = value);

  final proxyRes = await client.send(proxyReq);
  return proxyRes;
}
