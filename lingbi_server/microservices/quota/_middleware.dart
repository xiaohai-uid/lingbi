import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

// Middleware for common logging
final logRequests = (Handler innerHandler) {
  return (Request request) async {
    print('${request.method} ${request.url}');
    final response = await innerHandler(request);
    return response;
  };
};
