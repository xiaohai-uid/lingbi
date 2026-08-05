import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingbi/features/routing/experience/experience_journal.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';
import 'package:lingbi/services/ai_service.dart';
import 'package:lingbi/features/settings/data/quota_service.dart';

void main() {
  late Directory temp;
  late ExperienceJournal journal;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('lingbi_fusion_p2_');
    journal = ExperienceJournal(basePath: temp.path);
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  test('completed execution writes a searchable experience entry', () {
    journal.recordCompleted(
      scene: 'novel_continuation',
      userMessage: '帮我续写下一章',
      summary: '续写流程成功，建议先注入正典摘要。',
      nodeChain: const ['context_assembly', 'draft', 'gate', 'candidate'],
      outputGateResult: 'passed:1',
    );

    final entries = journal.search('novel_continuation');

    expect(entries, hasLength(1));
    expect(entries.first.outcome, ExperienceOutcome.completed);
    expect(entries.first.nodeChain, contains('draft'));
    expect(entries.first.outputGateResult, 'passed:1');
  });

  test('route miss and failed execution are recorded separately', () {
    journal.recordMiss(scene: 'weather', userMessage: '今天天气怎么样');
    journal.recordFailed(
      scene: 'polish',
      userMessage: '润色这段',
      summary: 'provider failed',
    );

    expect(journal.search('weather').single.outcome, ExperienceOutcome.miss);
    expect(journal.search('polish').single.outcome, ExperienceOutcome.failed);
  });

  test('SkillActionService writes completed and miss hooks', () {
    final service = SkillActionService(experienceJournal: journal)
      ..initializeBuiltinSkills();

    service.executeRouted(
      userMessage: '帮我续写下一章',
      context: const SkillContext(
        fullDocument: '这是一段足够长的前文内容，用于测试智能续写是否正常工作。',
      ),
      currentScene: 'novel_continuation',
    );
    service.routeTask(userMessage: '今天天气怎么样', currentScene: 'weather');

    expect(
      journal.search('novel_continuation').single.outcome,
      ExperienceOutcome.completed,
    );
    expect(journal.search('weather').single.outcome, ExperienceOutcome.miss);
  });

  test('AIService injects experience summary before routing', () {
    journal.recordCompleted(
      scene: 'novel_continuation',
      userMessage: '帮我续写下一章',
      summary: '历史经验：先注入正典摘要，再生成候选。',
    );
    final ai = AIService(
      quotaService: QuotaService(),
      experienceJournal: journal,
    );

    final prompt = ai.systemPromptFor(
      userMessage: '帮我续写下一章',
      currentScene: 'novel_continuation',
    );

    expect(prompt, contains('历史经验'));
    expect(prompt, contains('先注入正典摘要'));
  });
}
