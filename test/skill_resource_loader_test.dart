import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingbi/features/skill/data/skill/dynamic_prompt_skill.dart';
import 'package:lingbi/features/skill/data/skill/skill_loader.dart';
import 'package:lingbi/features/skill/data/skill_action_service.dart';

void main() {
  test('SkillLoader discovers references and readResource loads on demand',
      () async {
    final temp = await Directory.systemTemp.createTemp('lingbi_skill_res_');
    addTearDown(() => temp.delete(recursive: true));

    final skillDir = Directory('${temp.path}/test-skill')..createSync();
    File('${skillDir.path}/SKILL.md').writeAsStringSync('# Test Skill\n');
    Directory('${skillDir.path}/references').createSync();
    File('${skillDir.path}/references/characters.md').writeAsStringSync('人物资料');

    final actionService = SkillActionService();
    final loader = SkillLoader(actionService);
    await loader.loadAll(temp.path);

    final skill = actionService.getSkill('test-skill') as DynamicPromptSkill;
    expect(skill.referenceFiles, contains('characters.md'));
    expect(await skill.readResource('characters.md'), '人物资料');
    expect(await skill.readResource('../secret.txt'), isNull);
    expect(await skill.readResource('missing.md'), isNull);
  });
}
