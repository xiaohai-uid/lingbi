/// Short story adaptation workflow.
///
/// Derives a short story plan from project assets with stable character
/// identity preservation and recoverable state.
library;

import 'dart:convert';
import 'dart:io';

/// Source assets for adaptation.
class AdaptationSource {
  const AdaptationSource({
    required this.protagonist,
    required this.coreConflict,
    required this.worldRule,
    required this.theme,
  });

  final String protagonist;
  final String coreConflict;
  final String worldRule;
  final String theme;
}

/// A single structural beat in the short story plan.
class StoryStructureBeat {
  const StoryStructureBeat({
    required this.beat,
    required this.description,
    required this.targetWords,
  });

  final String beat;
  final String description;
  final int targetWords;

  Map<String, Object?> toJson() => {
        'beat': beat,
        'description': description,
        'target_words': targetWords,
      };
}

/// Character identity preserved across adaptation.
class CharacterIdentity {
  const CharacterIdentity({
    required this.protagonist,
    required this.coreTrait,
  });

  final String protagonist;
  final String coreTrait;

  Map<String, Object?> toJson() => {
        'protagonist': protagonist,
        'core_trait': coreTrait,
      };
}

/// A derived short story plan.
class ShortStoryPlan {
  const ShortStoryPlan({
    required this.id,
    required this.derivedFrom,
    required this.targetLength,
    required this.structure,
    required this.characterIdentity,
  });

  final String id;
  final String derivedFrom;
  final int targetLength;
  final List<StoryStructureBeat> structure;
  final CharacterIdentity characterIdentity;

  Map<String, Object?> toJson() => {
        'id': id,
        'derived_from': derivedFrom,
        'target_length': targetLength,
        'structure': structure.map((s) => s.toJson()).toList(),
        'character_identity': characterIdentity.toJson(),
      };
}

class ShortStoryWorkflow {
  ShortStoryWorkflow({required this.storageDir});

  final String storageDir;

  Future<ShortStoryPlan> derive({
    required String projectId,
    required AdaptationSource sourceAssets,
    required int targetLength,
  }) async {
    final id = 'ss-${DateTime.now().microsecondsSinceEpoch}';
    final wordsPerBeat = targetLength ~/ 5;

    final structure = [
      StoryStructureBeat(
        beat: 'Hook',
        description:
            'Open with ${sourceAssets.protagonist} facing ${sourceAssets.coreConflict}',
        targetWords: wordsPerBeat,
      ),
      StoryStructureBeat(
        beat: 'Escalation',
        description:
            'The ${sourceAssets.worldRule} constrains the protagonist\'s options',
        targetWords: wordsPerBeat,
      ),
      StoryStructureBeat(
        beat: 'Midpoint reversal',
        description:
            'A revelation reframes ${sourceAssets.coreConflict}',
        targetWords: wordsPerBeat,
      ),
      StoryStructureBeat(
        beat: 'Climax',
        description:
            '${sourceAssets.protagonist} confronts the core conflict directly',
        targetWords: wordsPerBeat,
      ),
      StoryStructureBeat(
        beat: 'Resolution',
        description:
            'Theme of ${sourceAssets.theme} is realized through the outcome',
        targetWords: targetLength - wordsPerBeat * 4,
      ),
    ];

    final plan = ShortStoryPlan(
      id: id,
      derivedFrom: projectId,
      targetLength: targetLength,
      structure: structure,
      characterIdentity: CharacterIdentity(
        protagonist: sourceAssets.protagonist,
        coreTrait: _extractCoreTrait(sourceAssets),
      ),
    );

    // Persist
    final dir = Directory('$storageDir/$projectId/short_stories');
    await dir.create(recursive: true);
    await File('${dir.path}/$id.json')
        .writeAsString(jsonEncode(plan.toJson()), flush: true);

    return plan;
  }

  String _extractCoreTrait(AdaptationSource source) {
    // Derive a core trait from the conflict description
    if (source.coreConflict.contains('revenge') ||
        source.coreConflict.contains('justice')) {
      return 'Driven by a need for justice';
    }
    if (source.coreConflict.contains('lost') ||
        source.coreConflict.contains('sacrifice')) {
      return 'Perseveres through loss';
    }
    return 'Defined by ${source.coreConflict}';
  }
}
