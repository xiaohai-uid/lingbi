import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../lib/quota_service.dart';

class ConsumeHandler {
  final QuotaService quotaService;

  ConsumeHandler(this.quotaService);

  Future<Response> post(RouterContext context) async {
    final result = quotaService.consume();
    return Response(200, body: jsonEncode(result));
  }
}
