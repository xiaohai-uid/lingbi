import 'package:flutter_test/flutter_test.dart';
import 'config.dart';
import 'helpers/health_helper.dart';

void main() {
  group('Microservice Health Checks', () {
    for (final entry in kServicePorts.entries) {
      test('${entry.key} should respond with 200 on /health', () async {
        final healthy = await checkServiceHealth(entry.value);
        expect(healthy, isTrue,
            reason: '${entry.key} at port ${entry.value} is not healthy');
      });
    }
  });
}
