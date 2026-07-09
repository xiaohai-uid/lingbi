import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

enum ConflictStrategy {
  sourceWins,
  destWins,
  newerWins,
  manual,
}

class ConflictResolver {
  final ConflictStrategy strategy;
  final List<Conflict> _conflicts = [];

  ConflictResolver({this.strategy = ConflictStrategy.sourceWins});

  void resolve(File localFile, File remoteFile) {
    final localStat = localFile.statSync();
    final remoteStat = remoteFile.statSync();

    // If files have different modification times
    if (localStat.modified != remoteStat.modified) {
      switch (strategy) {
        case ConflictStrategy.sourceWins:
          // Keep source (local) file
          localFile.copySync(remoteFile.path);
          break;
        case ConflictStrategy.destWins:
          // Keep destination (remote) file
          remoteFile.copySync(localFile.path);
          break;
        case ConflictStrategy.newerWins:
          // Keep newer file
          if (localStat.modified.isAfter(remoteStat.modified)) {
            localFile.copySync(remoteFile.path);
          } else {
            remoteFile.copySync(localFile.path);
          }
          break;
        case ConflictStrategy.manual:
          // Add to conflicts list for manual resolution
          _conflicts.add(Conflict(
            localPath: localFile.path,
            remotePath: remoteFile.path,
            localModified: localStat.modified,
            remoteModified: remoteStat.modified,
          ));
          break;
      }
    }
  }

  List<Conflict> getConflicts() => List.unmodifiable(_conflicts);

  void clearConflicts() => _conflicts.clear();

  String computeChecksum(String filePath) {
    final file = File(filePath);
    final bytes = file.readAsBytesSync();
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}

class Conflict {
  final String localPath;
  final String remotePath;
  final DateTime localModified;
  final DateTime remoteModified;

  Conflict({
    required this.localPath,
    required this.remotePath,
    required this.localModified,
    required this.remoteModified,
  });

  Map<String, dynamic> toJson() => {
        'local_path': localPath,
        'remote_path': remotePath,
        'local_modified': localModified.toIso8601String(),
        'remote_modified': remoteModified.toIso8601String(),
      };
}
