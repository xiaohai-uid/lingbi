import 'package:dart_frog/dart_frog.dart';

import 'package:lingbi_server/router.dart';

/// Middleware that routes requests to the appropriate microservice.
Handler middleware(Handler handler) {
  return handler.use(
    middleware(
      (context, handler) async {
        final requestPath = context.request.uri.path;
        for (final config in microservices) {
          if (requestPath.startsWith(config.pathPrefix)) {
            return handler(context);
          }
        }
        return handler(context);
      },
    ),
  );
}
