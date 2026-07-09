import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../lib/quota_service.dart';

/// GET /status — Get current quota status
Handler statusHandler(QuotaService quotaService) {
  return (Request request) async {
    try {
      final status = quotaService.getStatus();
      return Response.ok(
        jsonEncode(status),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  };
}
