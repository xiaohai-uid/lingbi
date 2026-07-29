import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'package:lingbi/services/atomic_file_store.dart';
import 'package:lingbi/services/migrations/schema_versions.dart';

class PortablePackageFile {
  const PortablePackageFile({
    required this.path,
    required this.sha256,
    required this.size,
    required this.category,
  });

  factory PortablePackageFile.fromJson(Map<String, dynamic> json) =>
      PortablePackageFile(
        path: json['path'] as String,
        sha256: json['sha256'] as String,
        size: json['size'] as int,
        category: json['category'] as String,
      );

  final String path;
  final String sha256;
  final int size;
  final String category;

  Map<String, dynamic> toJson() => {
        'path': path,
        'sha256': sha256,
        'size': size,
        'category': category,
      };
}

class PortablePackageManifest {
  const PortablePackageManifest({
    required this.schemaVersion,
    required this.exportedAt,
    required this.files,
  });

  factory PortablePackageManifest.fromJson(Map<String, dynamic> json) =>
      PortablePackageManifest(
        schemaVersion: json['schemaVersion'] as int,
        exportedAt: DateTime.parse(json['exportedAt'] as String),
        files: (json['files'] as List)
            .map((item) => PortablePackageFile.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  final int schemaVersion;
  final DateTime exportedAt;
  final List<PortablePackageFile> files;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'files': files.map((file) => file.toJson()).toList(),
      };
}

class PackageValidationResult {
  const PackageValidationResult(
      {required this.isValid, this.error, this.manifest});
  final bool isValid;
  final String? error;
  final PortablePackageManifest? manifest;
}

class PortableProjectPackageService {
  PortableProjectPackageService({
    AtomicFileStore? atomicStore,
    Future<void> Function(String directoryPath)? rebuildIndexes,
  })  : _atomicStore = atomicStore ?? AtomicFileStore(),
        _rebuildIndexes = rebuildIndexes;

  static const manifestName = 'lingbi-manifest.json';
  final AtomicFileStore _atomicStore;
  final Future<void> Function(String directoryPath)? _rebuildIndexes;

  Future<PortablePackageManifest> exportPackage(
    String projectDir,
    String packagePath,
  ) async {
    final root = Directory(projectDir);
    if (!await root.exists()) {
      throw FileSystemException('Project directory does not exist', projectDir);
    }
    final archive = Archive();
    final files = <PortablePackageFile>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative =
          p.relative(entity.path, from: root.path).replaceAll(r'\', '/');
      if (_isTransient(relative)) continue;
      final bytes = await entity.readAsBytes();
      archive.add(ArchiveFile.bytes(relative, bytes));
      files.add(PortablePackageFile(
        path: relative,
        sha256: sha256.convert(bytes).toString(),
        size: bytes.length,
        category: _category(relative),
      ));
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    final manifest = PortablePackageManifest(
      schemaVersion: SchemaVersions.portablePackage,
      exportedAt: DateTime.now().toUtc(),
      files: files,
    );
    archive
        .add(ArchiveFile.string(manifestName, jsonEncode(manifest.toJson())));
    await _atomicStore.writeBytes(
        packagePath, ZipEncoder().encodeBytes(archive));
    return manifest;
  }

  Future<PackageValidationResult> validatePackage(String packagePath) async {
    try {
      final archive = ZipDecoder()
          .decodeBytes(await File(packagePath).readAsBytes(), verify: true);
      final entries = <String, ArchiveFile>{
        for (final file in archive.files.where((file) => file.isFile))
          file.name: file,
      };
      final manifestEntry = entries[manifestName];
      if (manifestEntry == null) {
        throw const FormatException('Missing manifest');
      }
      final manifest = PortablePackageManifest.fromJson(
          jsonDecode(utf8.decode(manifestEntry.readBytes()!))
              as Map<String, dynamic>);
      if (manifest.schemaVersion != SchemaVersions.portablePackage) {
        throw const FormatException('Unsupported package schema');
      }
      for (final expected in manifest.files) {
        _validateRelativePath(expected.path);
        final actual = entries[expected.path];
        if (actual == null) throw FormatException('Missing ${expected.path}');
        final bytes = actual.readBytes()!;
        if (bytes.length != expected.size ||
            sha256.convert(bytes).toString() != expected.sha256) {
          throw FormatException('Checksum mismatch: ${expected.path}');
        }
      }
      return PackageValidationResult(isValid: true, manifest: manifest);
    } catch (error) {
      return PackageValidationResult(isValid: false, error: error.toString());
    }
  }

  Future<PortablePackageManifest> importPackage(
    String packagePath,
    String destinationDir,
  ) async {
    final validation = await validatePackage(packagePath);
    if (!validation.isValid || validation.manifest == null) {
      throw FormatException(validation.error ?? 'Invalid project package');
    }
    final destination = Directory(destinationDir);
    if (await destination.exists() && !(await destination.list().isEmpty)) {
      throw StateError('Import destination must be empty');
    }
    await destination.create(recursive: true);
    final archive =
        ZipDecoder().decodeBytes(await File(packagePath).readAsBytes());
    final entries = {for (final file in archive.files) file.name: file};
    for (final expected in validation.manifest!.files) {
      _validateRelativePath(expected.path);
      await _atomicStore.writeBytes(
        p.joinAll([destination.path, ...expected.path.split('/')]),
        entries[expected.path]!.readBytes()!,
      );
    }
    await _rebuildIndexes?.call(destination.path);
    return validation.manifest!;
  }

  static bool _isTransient(String path) =>
      path.endsWith('.tmp') || path.endsWith('.bak') || path == manifestName;

  static void _validateRelativePath(String value) {
    final normalized = p.posix.normalize(value);
    if (p.posix.isAbsolute(value) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw FormatException('Unsafe package path: $value');
    }
  }

  static String _category(String path) {
    if (path == '.lingbi/project.json') return 'brief';
    if (path.startsWith('.lingbi/assets')) return 'assets';
    if (path.startsWith('.lingbi/canon')) return 'canon';
    if (path.startsWith('.lingbi/candidates')) return 'candidates';
    if (path.startsWith('.lingbi/versions')) return 'versions';
    if (path.startsWith('.lingbi/memos')) return 'memos';
    if (path.startsWith('.lingbi/skills')) return 'skills';
    if (path.toLowerCase().endsWith('.md')) return 'documents';
    return 'project-data';
  }
}
