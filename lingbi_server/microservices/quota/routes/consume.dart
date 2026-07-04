import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../lib/quota_service.dart';

/// POST /consume — Consume one quota token
Handler consumeHandler(QuotaService quotaService) {
  return (Request request) async {
    try {
      final result = quotaService.consume();
      return Response.ok(
        jsonEncode(result),
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