/// SkillService — Flutter 端 Skill 管理客户端
///
/// 通过 HTTP 调用 Skill Service (Rust) 的 API。
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Skill 数据模型
class Skill {
  final String id;
  final String name;
  final String version;
  final String type;
  final String author;
  final String description;
  final String icon;
  final String promptTemplate;
  final Map<String, String> variables;
  final String category;

  const Skill({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.type = 'writing',
    this.author = 'anonymous',
    this.description = '',
    this.icon = '🔧',
    this.promptTemplate = '',
    this.variables = const {},
    this.category = 'general',
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '1.0.0',
    type: json['skill_type'] as String? ?? 'writing',
    author: json['author'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? '🔧',
    promptTemplate: json['prompt_template'] as String? ?? '',
    variables: (json['variables'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString()),
    ) ?? {},
    category: json['category'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'skill_type': type,
    'author': author,
    'description': description,
    'icon': icon,
    'prompt_template': promptTemplate,
    'variables': variables,
    'category': category,
  };
}

/// Skill 执行结果
class SkillExecuteResult {
  final String result;
  final String skillId;
  final int tokensUsed;

  const SkillExecuteResult({
    required this.result,
    required this.skillId,
    this.tokensUsed = 0,
  });
}

/// 风格蒸馏结果
class DistillResult {
  final Skill skill;
  final String skillJson;

  const DistillResult({required this.skill, required this.skillJson});
}

/// Skill 服务客户端
class SkillService {
  SkillService({this.baseUrl = 'http://localhost:8097'});

  final String baseUrl;
  final http.Client _client = http.Client();

  /// 获取所有 Skill
  Future<List<Skill>> listSkills({int page = 1, int pageSize = 20}) async {
    final uri = Uri.parse('$baseUrl/api/v1/skills?page=$page&page_size=$pageSize');
    final resp = await _client.get(uri);
    if (resp.statusCode != 200) throw StateError('Failed to list skills');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['skills'] as List).map((s) => Skill.fromJson(s)).toList();
  }

  /// 获取单个 Skill
  Future<Skill> getSkill(String id) async {
    final resp = await _client.get(Uri.parse('$baseUrl/api/v1/skills/$id'));
    if (resp.statusCode != 200) throw StateError('Skill not found');
    return Skill.fromJson(jsonDecode(resp.body));
  }

  /// 创建 Skill
  Future<Skill> createSkill(Skill skill) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/skills'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(skill.toJson()),
    );
    if (resp.statusCode != 201) throw StateError('Failed to create skill');
    return Skill.fromJson(jsonDecode(resp.body));
  }

  /// 执行 Skill
  Future<SkillExecuteResult> executeSkill(
    String skillId, {
    Map<String, String> variables = const {},
    String? context,
  }) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/skills/$skillId/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'skill_id': skillId,
        'variables': variables,
        'context': context,
      }),
    );
    if (resp.statusCode != 200) throw StateError('Failed to execute skill');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return SkillExecuteResult(
      result: body['result'] as String? ?? '',
      skillId: body['skill_id'] as String? ?? skillId,
      tokensUsed: body['tokens_used'] as int? ?? 0,
    );
  }

  /// 风格蒸馏 → 生成 Skill
  Future<DistillResult> distillStyle(String text, String name, {String? author}) async {
    final resp = await _client.post(
      Uri.parse('$baseUrl/api/v1/skills/distill'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'name': name,
        'author': author,
      }),
    );
    if (resp.statusCode != 200) throw StateError('Failed to distill style');
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return DistillResult(
      skill: Skill.fromJson(body['skill']),
      skillJson: body['skill_json'] as String? ?? '',
    );
  }
}
