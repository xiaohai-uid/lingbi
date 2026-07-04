import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../lib/quota_service.dart';

class ResetHandler {
  final QuotaService quotaService;

  ResetHandler(this.quotaService);

  Future<Response> put(RouterContext context) async {
    final result = quotaService.reset();
    return Response(200, body: jsonEncode(result));
  }
}
