import 'dart:io';

import 'package:path/path.dart' as p;

/// Skill Level 3 resource loader.
///
/// Lists and reads optional files under `references/` on demand instead of
/// loading every attachment into memory during skill discovery.
class SkillResourceLoader {
  const SkillResourceLoader({this.maxFileBytes = 256 * 1024});

  final int maxFileBytes;

  /// Returns project-relative reference paths, sorted for stable UI/test use.
  Future<List<String>> listReferences(String skillDir) async {
    final references = Directory(p.join(skillDir, 'references'));
    if (!await references.exists()) return const [];
    final files = <String>[];
    await for (final entity in references.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        files.add(
          p.relative(entity.path, from: references.path).replaceAll(r'\', '/'),
        );
      }
    }
    files.sort();
    return files;
  }

  /// Reads one reference file, rejecting traversal and oversized files.
  Future<String?> read(String skillDir, String relativePath) async {
    final references = Directory(p.join(skillDir, 'references'));
    final normalized = p.posix.normalize(relativePath.replaceAll(r'\', '/'));
    if (p.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.split('/').contains('..')) {
      return null;
    }
    final target = File(
      p.joinAll([references.path, ...normalized.split('/')]),
    );
    if (!p.isWithin(references.path, target.path)) return null;
    if (!await target.exists()) return null;
    try {
      if (await target.length() > maxFileBytes) return null;
      return await target.readAsString();
    } catch (_) {
      return null;
    }
  }
}
