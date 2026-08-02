/// Wires FakeConformanceProvider into the conformance suite.
///
/// Task C1: Validates the suite itself passes with the deterministic fake.
library;

import 'support/fake_conformance_provider.dart';
import 'support/provider_conformance_suite.dart';

void main() {
  // Run with tool support enabled
  runProviderConformanceSuite(() => FakeConformanceProvider());

  // Run without tool support (tests the UnsupportedError path)
  runProviderConformanceSuite(
    () => FakeConformanceProvider(toolSupport: false),
  );
}
