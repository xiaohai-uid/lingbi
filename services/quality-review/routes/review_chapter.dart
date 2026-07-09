import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_quality_review/models/review_models.dart';
import 'package:lingbi_quality_review/review_pipeline.dart';
import 'package:lingbi_quality_review/character_consistency.dart';
import 'package:lingbi_quality_review/hook_density.dart';
import 'package:lingbi_quality_review/format_review.dart';
import 'package:lingbi_quality_review/llm_client.dart';

/// POST /review/chapter — 章节质量审查（含各场景子报告）
///
/// Body: {
///   chapterId, title?, genre?, useLlm?,
///   scenes: [{ id, title?, text }]
/// }
/// Returns: { chapterId, title, overall, scenes: [ReviewReport...] }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  try {
    final body =
        jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final scenes = (body['scenes'] as List?) ?? [];
    if (scenes.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'scenes is required and non-empty'},
      );
    }
    final characters = (body['characters'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final useLlm = body['useLlm'] as bool? ?? false;
    final llmClient = useLlm ? LLMClient() : null;

    final sceneReports = <Map<String, dynamic>>[];
    String merged = '';
    for (final s in scenes) {
      final sMap = s as Map<String, dynamic>;
      final text = sMap['text'] as String? ?? '';
      if (text.isEmpty) continue;
      merged += text + '
';
      final pipeline = ReviewPipeline(
        characterConsistency: CharacterConsistency(
          characterProfiles: characters,
          llmClient: llmClient,
        ),
        hookDensity: HookDensity(llmClient: llmClient),
        formatReview: FormatReview(llmClient: llmClient),
      );
      final report = await pipeline.analyze(text);
      sceneReports.add({
        'sceneId': sMap['id'] ?? '',
        'title': sMap['title'] ?? '',
        ...report.toJson(),
      });
    }

    if (merged.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'no non-empty scene text provided'},
      );
    }

    final overallPipeline = ReviewPipeline(
      characterConsistency: CharacterConsistency(
        characterProfiles: characters,
        llmClient: llmClient,
      ),
      hookDensity: HookDensity(llmClient: llmClient),
      formatReview: FormatReview(llmClient: llmClient),
    );
    final overall = await overallPipeline.analyze(merged);

    return Response.json(
      body: {
        'chapterId': body['chapterId'] ?? '',
        'title': body['title'] ?? '',
        ...overall.toJson(),
        'scenes': sceneReports,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
