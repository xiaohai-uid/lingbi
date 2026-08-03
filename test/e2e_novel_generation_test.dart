@Tags(['network'])
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// 灵笔端到端小说生成测试
/// 使用 SenseNova 免费 API (deepseek-v4-flash) 生成 1万字+ 小说
void main() async {
  final apiKey = Platform.environment['SENSENOVA_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('SENSENOVA_API_KEY 未设置，跳过真实网络生成测试');
    return;
  }

  const baseUrl = 'https://token.sensenova.cn/v1/chat/completions';
  const model = 'deepseek-v4-flash';
  final client = http.Client();
  final output = StringBuffer();
  var totalChars = 0;

  Future<String> chat(String system, String user, {int maxTokens = 4096}) async {
    final resp = await client.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        'temperature': 0.8,
        'max_tokens': maxTokens,
      }),
    ).timeout(const Duration(seconds: 120));

    if (resp.statusCode != 200) {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body);
    return data['choices'][0]['message']['content'] as String;
  }

  print('=== 灵笔端到端小说生成测试 ===');
  print('模型: $model');
  print('目标: 生成 10,000+ 字小说\n');

  // Step 1: 生成大纲
  print('[1/6] 生成小说大纲...');
  final outline = await chat(
    '你是一位资深网络小说作家，擅长玄幻题材。请为用户创作一部完整的短篇小说大纲。',
    '''请创作一部玄幻小说的大纲，要求：
- 标题：《星渊剑主》
- 类型：玄幻/修仙
- 字数规划：约12000字，分6章
- 包含：主角设定、世界观、核心冲突、每章概要（每章200字左右）
- 主角：叶尘，一个被家族废弃的少年，偶得上古星渊剑传承
- 设定：星渊大陆，以星力修炼为主

请直接输出大纲，不要多余解释。''',
    maxTokens: 2048,
  );
  output.writeln('# 星渊剑主\n\n## 大纲\n\n$outline\n\n---\n');
  totalChars += outline.length;
  print('  大纲完成: ${outline.length} 字');

  // Step 2-7: 逐章生成
  for (var chapter = 1; chapter <= 6; chapter++) {
    print('[${chapter + 1}/6] 生成第 $chapter 章...');
    final chapterText = await chat(
      '''你是一位资深网络小说作家，正在创作玄幻小说《星渊剑主》。
世界观：星渊大陆，以星力修炼为主，境界分为：聚星境、凝星境、星核境、星魂境、星王境。
主角：叶尘，16岁，叶家废弃少年，偶得上古星渊剑传承。
风格：节奏紧凑，打斗精彩，适当对话，每章2000字左右。

大纲如下：
$outline''',
      '''请写第 $chapter 章的完整正文。要求：
- 2000字左右
- 有场景描写、对话、打斗
- 章节开头用"第X章 标题"格式
- 直接输出正文，不要解释''',
      maxTokens: 4096,
    );
    output.writeln('\n$chapterText\n');
    totalChars += chapterText.length;
    print('  第 $chapter 章完成: ${chapterText.length} 字 (累计: $totalChars)');
  }

  // 保存结果
  final outFile = File('test_output_novel.md');
  await outFile.writeAsString(output.toString(), encoding: utf8);
  
  print('\n=== 测试完成 ===');
  print('总字数: $totalChars');
  print('输出文件: ${outFile.absolute.path}');
  print('结果: ${totalChars >= 10000 ? "PASS ✓" : "FAIL ✗ (不足10000字)"}');
  
  client.close();
}
