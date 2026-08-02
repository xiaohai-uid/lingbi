/// Drama adaptation workflow.
///
/// Converts story beats into scene/shot structure with full traceability
/// back to source beats. Supports structured export.
library;

import 'dart:convert';
import 'dart:io';

/// A source story beat from the novel.
class StoryBeat {
  const StoryBeat({
    required this.id,
    required this.chapter,
    required this.summary,
  });

  final String id;
  final int chapter;
  final String summary;
}

/// A shot within a scene, linked to a source beat.
class Shot {
  const Shot({
    required this.id,
    required this.sourceBeatId,
    required this.description,
    required this.duration,
  });

  final String id;
  final String sourceBeatId;
  final String description;
  final String duration;

  Map<String, Object?> toJson() => {
        'id': id,
        'source_beat_id': sourceBeatId,
        'description': description,
        'duration': duration,
      };
}

/// A scene containing multiple shots.
class Scene {
  const Scene({
    required this.id,
    required this.title,
    required this.shots,
  });

  final String id;
  final String title;
  final List<Shot> shots;

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'shots': shots.map((s) => s.toJson()).toList(),
      };
}

/// An episode containing scenes.
class Episode {
  const Episode({
    required this.number,
    required this.scenes,
  });

  final int number;
  final List<Scene> scenes;

  Map<String, Object?> toJson() => {
        'number': number,
        'scenes': scenes.map((s) => s.toJson()).toList(),
      };
}

/// The full drama adaptation result.
class DramaAdaptation {
  const DramaAdaptation({
    required this.projectId,
    required this.episodes,
  });

  final String projectId;
  final List<Episode> episodes;

  Map<String, Object?> toJson() => {
        'project_id': projectId,
        'episodes': episodes.map((e) => e.toJson()).toList(),
      };
}

class DramaAdaptationWorkflow {
  DramaAdaptationWorkflow({required this.storageDir});

  final String storageDir;

  Future<DramaAdaptation> adapt({
    required String projectId,
    required List<StoryBeat> sourceBeats,
    required int episodeTarget,
  }) async {
    // Group beats into scenes (one scene per beat for simplicity)
    final scenes = <Scene>[];
    for (var i = 0; i < sourceBeats.length; i++) {
      final beat = sourceBeats[i];
      scenes.add(Scene(
        id: 'scene-${i + 1}',
        title: beat.summary,
        shots: [
          Shot(
            id: 'shot-${i + 1}-1',
            sourceBeatId: beat.id,
            description: 'Establishing: ${beat.summary}',
            duration: '3-5s',
          ),
          Shot(
            id: 'shot-${i + 1}-2',
            sourceBeatId: beat.id,
            description: 'Action: ${beat.summary}',
            duration: '5-10s',
          ),
        ],
      ));
    }

    final episodes = <Episode>[];
    for (var ep = 1; ep <= episodeTarget; ep++) {
      episodes.add(Episode(number: ep, scenes: scenes));
    }

    final result = DramaAdaptation(projectId: projectId, episodes: episodes);

    // Persist
    final dir = Directory('$storageDir/$projectId/drama');
    await dir.create(recursive: true);
    await File('${dir.path}/adaptation.json')
        .writeAsString(jsonEncode(result.toJson()), flush: true);

    return result;
  }

  /// Export to structured text format.
  String export(DramaAdaptation adaptation) {
    final buffer = StringBuffer();
    for (final episode in adaptation.episodes) {
      buffer.writeln('Episode ${episode.number}');
      buffer.writeln('=' * 40);
      for (final scene in episode.scenes) {
        buffer.writeln('  Scene: ${scene.title}');
        for (final shot in scene.shots) {
          buffer.writeln(
              '    Shot [${shot.id}] (${shot.duration}): ${shot.description}');
          buffer.writeln('      -> source: ${shot.sourceBeatId}');
        }
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
