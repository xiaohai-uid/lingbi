import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../config.dart';

/// 检查单个微服务健康状态
Future<bool> checkServiceHealth(int port, {Duration? timeout}) async {
  try {
    final client = HttpClient();
    client.connectionTimeout = timeout ?? kHealthTimeout;
    final request = await client.getUrl(Uri.parse(healthUrl(port)));
    final response = await request.close();
    await response.drain();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// 等待所有微服务就绪
Future<void> waitForAllServices(
  Map<String, int> services, {
  Duration interval = kHealthInterval,
  int maxRetries = kMaxRetries,
}) async {
  final notReady = <String, int>{...services};
  for (var i = 0; i < maxRetries && notReady.isNotEmpty; i++) {
    for (final entry in notReady.entries.toList()) {
      final healthy = await checkServiceHealth(entry.value);
      if (healthy) {
        debugPrint('✅ ${entry.key} (:${entry.value}) is healthy');
        notReady.remove(entry.key);
      }
    }
    if (notReady.isNotEmpty && i < maxRetries - 1) {
      debugPrint(
        '⏳ Waiting for ${notReady.length} service(s): '
        '${notReady.values.join(', ')} (attempt ${i + 1}/$maxRetries)',
      );
      await Future.delayed(interval);
    }
  }
  if (notReady.isNotEmpty) {
    throw StateError(
      'Services not ready after $maxRetries retries: ${notReady.keys.join(', ')}',
    );
  }
}

/// 服务基础 URL
String serviceUrl(int port, [String path = '']) =>
    'http://localhost:$port$path';
