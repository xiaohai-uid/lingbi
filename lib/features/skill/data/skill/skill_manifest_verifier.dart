import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

enum SkillPackageState { production, development, test }

enum SkillSignatureStatus { verified, unsignedDevelopment, rejected }

enum SkillVerificationFailure {
  invalidManifest,
  pathEscape,
  undeclaredFile,
  missingFile,
  hashMismatch,
  versionRollback,
  noTrustedRoot,
  untrustedSigner,
  invalidSignature,
  unsignedProduction,
  testSignerDisabled,
}

class SkillTrustedSigner {
  const SkillTrustedSigner({
    required this.id,
    required this.key,
    this.testOnly = false,
  });

  const SkillTrustedSigner.testOnly({required this.id, required this.key})
      : testOnly = true;

  final String id;
  final String key;
  final bool testOnly;
}

class SkillPackageManifest {
  SkillPackageManifest({
    required this.skillId,
    required this.version,
    required Map<String, String> files,
    required Set<String> capabilities,
    required this.signerId,
    required this.signature,
    this.state = SkillPackageState.production,
  })  : files = Map.unmodifiable(files),
        capabilities = Set.unmodifiable(capabilities);

  factory SkillPackageManifest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final rawCapabilities = json['capabilities'];
    if (rawFiles is! Map || rawCapabilities is! List) {
      throw const FormatException('Invalid skill package manifest');
    }
    return SkillPackageManifest(
      skillId: json['skill_id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      files: rawFiles.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      capabilities: rawCapabilities.map((value) => value.toString()).toSet(),
      signerId: json['signer_id'] as String?,
      signature: json['signature'] as String?,
      state: SkillPackageState.values.firstWhere(
        (state) => state.name == json['state'],
        orElse: () => SkillPackageState.production,
      ),
    );
  }

  final String skillId;
  final String version;
  final Map<String, String> files;
  final Set<String> capabilities;
  final String? signerId;
  final String? signature;
  final SkillPackageState state;

  SkillPackageManifest copyWith({String? signature}) => SkillPackageManifest(
        skillId: skillId,
        version: version,
        files: files,
        capabilities: capabilities,
        signerId: signerId,
        signature: signature,
        state: state,
      );

  Map<String, Object?> toJson() => {
        'skill_id': skillId,
        'version': version,
        'files': files,
        'capabilities': capabilities.toList()..sort(),
        'signer_id': signerId,
        'signature': signature,
        'state': state.name,
      };

  String get canonicalPayload {
    final sortedFiles = Map.fromEntries(
      files.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final sortedCapabilities = capabilities.toList()..sort();
    return jsonEncode({
      'skill_id': skillId,
      'version': version,
      'files': sortedFiles,
      'capabilities': sortedCapabilities,
      'signer_id': signerId,
      'state': state.name,
    });
  }
}

class SkillManifestVerificationResult {
  SkillManifestVerificationResult({
    required Set<SkillVerificationFailure> failures,
    required this.signatureStatus,
  }) : failures = Set.unmodifiable(failures);

  final Set<SkillVerificationFailure> failures;
  final SkillSignatureStatus signatureStatus;

  bool get isValid => failures.isEmpty;
}

class SkillManifestVerifier {
  const SkillManifestVerifier({
    this.trustedSigners = const {},
    this.allowDevelopmentUnsigned = false,
    this.allowTestSigners = false,
  });

  const SkillManifestVerifier.production()
      : trustedSigners = const {},
        allowDevelopmentUnsigned = false,
        allowTestSigners = false;

  const SkillManifestVerifier.development()
      : trustedSigners = const {},
        allowDevelopmentUnsigned = true,
        allowTestSigners = false;

  final Map<String, SkillTrustedSigner> trustedSigners;
  final bool allowDevelopmentUnsigned;
  final bool allowTestSigners;

  SkillManifestVerificationResult verify({
    required SkillPackageManifest manifest,
    required Map<String, List<int>> packageFiles,
    String? installedVersion,
  }) {
    final failures = <SkillVerificationFailure>{};

    if (manifest.skillId.trim().isEmpty ||
        !_isVersion(manifest.version) ||
        manifest.files.isEmpty) {
      failures.add(SkillVerificationFailure.invalidManifest);
    }

    for (final declaredPath in manifest.files.keys) {
      if (!_isSafeRelativePath(declaredPath)) {
        failures.add(SkillVerificationFailure.pathEscape);
      }
      final bytes = packageFiles[declaredPath];
      if (bytes == null) {
        failures.add(SkillVerificationFailure.missingFile);
      } else if (!_constantTimeEquals(
        sha256.convert(bytes).toString(),
        manifest.files[declaredPath]!.toLowerCase(),
      )) {
        failures.add(SkillVerificationFailure.hashMismatch);
      }
    }
    for (final packagePath in packageFiles.keys) {
      if (!_isSafeRelativePath(packagePath)) {
        failures.add(SkillVerificationFailure.pathEscape);
      }
      if (!manifest.files.containsKey(packagePath)) {
        failures.add(SkillVerificationFailure.undeclaredFile);
      }
    }

    if (installedVersion != null &&
        _compareVersions(manifest.version, installedVersion) < 0) {
      failures.add(SkillVerificationFailure.versionRollback);
    }

    final signatureStatus = _verifySignature(manifest, failures);
    return SkillManifestVerificationResult(
      failures: failures,
      signatureStatus: signatureStatus,
    );
  }

  SkillSignatureStatus _verifySignature(
    SkillPackageManifest manifest,
    Set<SkillVerificationFailure> failures,
  ) {
    final signerId = manifest.signerId;
    final signature = manifest.signature;
    if (signerId == null || signature == null || signature.isEmpty) {
      if (allowDevelopmentUnsigned &&
          manifest.state == SkillPackageState.development) {
        return SkillSignatureStatus.unsignedDevelopment;
      }
      failures.add(SkillVerificationFailure.unsignedProduction);
      return SkillSignatureStatus.rejected;
    }

    if (trustedSigners.isEmpty) {
      failures.add(SkillVerificationFailure.noTrustedRoot);
      return SkillSignatureStatus.rejected;
    }
    final signer = trustedSigners[signerId];
    if (signer == null) {
      failures.add(SkillVerificationFailure.untrustedSigner);
      return SkillSignatureStatus.rejected;
    }
    if (signer.testOnly && !allowTestSigners) {
      failures.add(SkillVerificationFailure.testSignerDisabled);
      return SkillSignatureStatus.rejected;
    }
    final expected = _signature(manifest, signer.key);
    if (!_constantTimeEquals(expected, signature.toLowerCase())) {
      failures.add(SkillVerificationFailure.invalidSignature);
      return SkillSignatureStatus.rejected;
    }
    return SkillSignatureStatus.verified;
  }

  static String createTestSignature(
    SkillPackageManifest manifest, {
    required String key,
  }) =>
      _signature(manifest, key);

  static String _signature(SkillPackageManifest manifest, String key) {
    return Hmac(sha256, utf8.encode(key))
        .convert(utf8.encode(manifest.canonicalPayload))
        .toString();
  }

  static bool _isSafeRelativePath(String value) {
    if (value.isEmpty || path.isAbsolute(value)) return false;
    final normalizedSeparators = value.replaceAll(r'\', '/');
    final segments = normalizedSeparators.split('/');
    if (segments.any((segment) => segment == '..' || segment.isEmpty)) {
      return false;
    }
    final normalized = path.posix.normalize(normalizedSeparators);
    return normalized != '..' && !normalized.startsWith('../');
  }

  static bool _isVersion(String version) {
    return RegExp(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$').hasMatch(version);
  }

  static int _compareVersions(String left, String right) {
    List<int> parts(String value) => value
        .split('-')
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? -1)
        .toList();
    final a = parts(left);
    final b = parts(right);
    for (var index = 0; index < 3; index++) {
      final comparison = a[index].compareTo(b[index]);
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  static bool _constantTimeEquals(String left, String right) {
    final a = Uint8List.fromList(utf8.encode(left));
    final b = Uint8List.fromList(utf8.encode(right));
    var difference = a.length ^ b.length;
    final length = a.length > b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      difference |= a[index % a.length] ^ b[index % b.length];
    }
    return difference == 0;
  }
}
