import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:lingbi_quality_review/models/review_models.dart';
import 'package:lingbi_quality_review/review_pipeline.dart';
import 'package:lingbi_quality_review/character_consistency.dart';
import 'package:lingbi_quality_review/hook_density.dart';
import 'package:lingbi_quality_review/format_review.dart';
import 'package:lingbi_quality_review/llm_client.dart';

/// POST /review/scene — 单场景质量审查
///
/// Body: { sceneId, title?, text, characters?, genre?, useLlm? }
/// Returns: { sceneId, title, ...ReviewReport }
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }
  try {
    final body =
        jsonDecode(await context.request.body()) as Map<String, dynamic>;
    final text = body['text'] as String? ?? '';
    if (text.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'text is required'},
      );
    }
    final characters = (body['characters'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final useLlm = body['useLlm'] as bool? ?? false;
    final llmClient = useLlm ? LLMClient() : null;
    final pipeline = ReviewPipeline(
      characterConsistency: CharacterConsistency(
        characterProfiles: characters,
        llmClient: llmClient,
      ),
      hookDensity: HookDensity(llmClient: llmClient),
      formatReview: FormatReview(llmClient: llmClient),
    );
    final report = await pipeline.analyze(text);
    return Response.json(
      body: {
        'sceneId': body['sceneId'] ?? '',
        'title': body['title'] ?? '',
        ...report.toJson(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'error': e.toString()},
    );
  }
}
