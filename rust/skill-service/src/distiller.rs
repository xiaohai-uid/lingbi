use serde_json::json;
use chrono::Utc;
use uuid::Uuid;
use crate::models::{Skill, DistillRequest, DistillResponse};

/// 风格蒸馏器 — 将文本风格提取为可复用的 Skill
pub struct StyleDistiller;

impl StyleDistiller {
    /// 从文本中蒸馏风格并生成 Skill
    pub fn distill(req: DistillRequest) -> DistillResponse {
        let now = Utc::now();
        let skill = Skill {
            id: Uuid::new_v4().to_string(),
            name: req.name.clone(),
            version: "1.0.0".to_string(),
            skill_type: "style".to_string(),
            author: req.author.unwrap_or_else(|| "anonymous".to_string()),
            description: format!("Auto-distilled style from: {}", req.name),
            icon: "🎨".to_string(),
            prompt_template: Self::build_style_prompt(&req.text),
            variables: json!({
                "user_text": "The text to rewrite in this style"
            }),
            category: "style".to_string(),
            downloads: 0,
            rating: 0.0,
            source: "local".to_string(),
            created_at: now,
            updated_at: now,
        };

        let skill_json = serde_json::to_string_pretty(&json!({
            "skill": {
                "name": skill.name,
                "version": skill.version,
                "type": skill.skill_type,
                "author": skill.author,
                "description": skill.description,
                "icon": skill.icon,
                "prompt_template": skill.prompt_template,
                "variables": skill.variables,
                "category": skill.category,
            }
        }))
        .unwrap_or_default();

        DistillResponse { skill, skill_json }
    }

    /// 构建风格模仿 prompt 模板
    fn build_style_prompt(text: &str) -> String {
        format!(
            r#"你是一个风格模仿专家。请根据以下参考文本的写作风格，处理用户的输入文本。

## 参考风格来源
```
{text}
```

## 风格特征
- 保持原作的语调、用词偏好和句式结构
- 模仿其节奏感和修辞手法
- 保持人物对话风格一致

## 用户输入
{{{{user_text}}}}

请直接输出处理后的文本，不要额外说明。"#,
            text = text
        )
    }
}
