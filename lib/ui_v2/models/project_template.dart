import 'package:flutter/material.dart';

/// A user-facing starting point. IDs are persisted and must remain stable.
final class ProjectTemplate {
  const ProjectTemplate({
    required this.templateId,
    required this.genreId,
    required this.genreLabel,
    required this.description,
    required this.icon,
  });

  final String templateId;
  final String genreId;
  final String genreLabel;
  final String description;
  final IconData icon;

  static const freeform = ProjectTemplate(
    templateId: 'freeform',
    genreId: '',
    genreLabel: '自由创作',
    description: '从一个名字或想法开始',
    icon: Icons.edit_note_outlined,
  );

  static const values = <ProjectTemplate>[
    ProjectTemplate(
      templateId: 'genre:xuanhuan',
      genreId: 'xuanhuan',
      genreLabel: '玄幻',
      description: '神秘大陆、修行之路',
      icon: Icons.auto_stories_outlined,
    ),
    ProjectTemplate(
      templateId: 'genre:urban',
      genreId: 'urban',
      genreLabel: '都市',
      description: '现代都市、职场商战',
      icon: Icons.business_outlined,
    ),
    ProjectTemplate(
      templateId: 'genre:suspense',
      genreId: 'suspense',
      genreLabel: '悬疑',
      description: '推理探案、心理惊悚',
      icon: Icons.search_outlined,
    ),
    ProjectTemplate(
      templateId: 'genre:romance',
      genreId: 'romance',
      genreLabel: '言情',
      description: '浪漫爱情、情感纠葛',
      icon: Icons.favorite_outline,
    ),
    ProjectTemplate(
      templateId: 'genre:scifi',
      genreId: 'scifi',
      genreLabel: '科幻',
      description: '未来世界、星际冒险',
      icon: Icons.rocket_launch_outlined,
    ),
    ProjectTemplate(
      templateId: 'genre:history',
      genreId: 'history',
      genreLabel: '历史',
      description: '古代王朝、历史演绎',
      icon: Icons.account_balance_outlined,
    ),
  ];

  static ProjectTemplate? byGenreId(String genreId) {
    for (final template in values) {
      if (template.genreId == genreId) return template;
    }
    return null;
  }
}
