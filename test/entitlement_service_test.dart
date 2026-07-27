import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/services/entitlements/entitlement_service.dart';
import 'package:lingbi/services/entitlements/license_signature_verifier.dart';
import 'package:lingbi/services/billing/billing_gateway.dart';

void main() {
  late Directory tempDir;
  late EntitlementService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('lingbi_entitle_');
    service = EntitlementService(storageDir: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('signed offline license', () {
    test('accepts a valid signed license', () async {
      final license = LicenseSignatureVerifier.createTestLicense(
        licensee: 'user-a',
        product: 'lingbi-pro',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        key: 'test-key',
      );

      final result = await service.activateLicense(
        licenseData: license.serialized,
        verifier: LicenseSignatureVerifier.testOnly(key: 'test-key'),
      );

      expect(result.activated, isTrue);
      expect(result.product, 'lingbi-pro');
      expect(result.licensee, 'user-a');
    });

    test('rejects a tampered license', () async {
      final license = LicenseSignatureVerifier.createTestLicense(
        licensee: 'user-a',
        product: 'lingbi-pro',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        key: 'test-key',
      );

      // Tamper with the serialized data
      final tampered = license.serialized.replaceFirst('user-a', 'user-X');

      final result = await service.activateLicense(
        licenseData: tampered,
        verifier: LicenseSignatureVerifier.testOnly(key: 'test-key'),
      );

      expect(result.activated, isFalse);
      expect(result.failureReason, contains('signature'));
    });

    test('rejects an expired license', () async {
      final license = LicenseSignatureVerifier.createTestLicense(
        licensee: 'user-a',
        product: 'lingbi-pro',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        key: 'test-key',
      );

      final result = await service.activateLicense(
        licenseData: license.serialized,
        verifier: LicenseSignatureVerifier.testOnly(key: 'test-key'),
      );

      expect(result.activated, isFalse);
      expect(result.failureReason, contains('expired'));
    });
  });

  group('local content access', () {
    test('local content is never locked behind payment', () async {
      // No license activated
      final canAccess = await service.canAccessLocalContent('proj-1');
      expect(canAccess, isTrue);
    });

    test('export and read remain available after license expiry', () async {
      final license = LicenseSignatureVerifier.createTestLicense(
        licensee: 'user-a',
        product: 'lingbi-pro',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        key: 'test-key',
      );
      await service.activateLicense(
        licenseData: license.serialized,
        verifier: LicenseSignatureVerifier.testOnly(key: 'test-key'),
      );

      // Even with expired license, local content is accessible
      final canAccess = await service.canAccessLocalContent('proj-1');
      expect(canAccess, isTrue);
    });
  });

  group('billing gateway boundary', () {
    test('production gateway is disabled without merchant credentials', () {
      const gateway = BillingGateway.production();
      expect(gateway.isEnabled, isFalse);
      expect(gateway.disabledReason, contains('merchant'));
    });

    test('purchase attempt on disabled gateway returns blocked status', () async {
      const gateway = BillingGateway.production();
      final result = await gateway.initiatePurchase(
        productId: 'lingbi-pro-annual',
        userId: 'user-a',
      );

      expect(result.success, isFalse);
      expect(result.status, PurchaseStatus.blockedExternal);
    });
  });

  group('offline grace period', () {
    test('grants grace period when network is unavailable', () async {
      // Activate a valid license first
      final license = LicenseSignatureVerifier.createTestLicense(
        licensee: 'user-a',
        product: 'lingbi-pro',
        expiresAt: DateTime.now().add(const Duration(days: 365)),
        key: 'test-key',
      );
      await service.activateLicense(
        licenseData: license.serialized,
        verifier: LicenseSignatureVerifier.testOnly(key: 'test-key'),
      );

      // Simulate offline validation
      final status = await service.validateEntitlement(
        networkAvailable: false,
      );

      expect(status.isValid, isTrue);
      expect(status.gracePeriodActive, isTrue);
    });
  });
}
