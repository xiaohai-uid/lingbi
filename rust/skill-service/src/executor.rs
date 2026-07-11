use reqwest::Client;
use serde_json::json;
use crate::models::Skill;

/// Skill 执行引擎
#[derive(Clone)]
pub struct SkillExecutor {
    ai_provider_url: String,
    client: Client,
}

impl SkillExecutor {
    pub fn new(ai_provider_url: String) -> Self {
        Self {
            ai_provider_url,
            client: Client::new(),
        }
    }

    /// 渲染 prompt 模板并调用 AI Provider
    pub async fn execute(
        &self,
        skill: &Skill,
        variables: &std::collections::HashMap<String, String>,
        context: Option<&str>,
    ) -> Result<(String, i32), String> {
        // 1. 渲染模板
        let mut prompt = skill.prompt_template.clone();
        for (key, value) in variables {
            prompt = prompt.replace(&format!("{{{{{}}}}}", key), value);
        }
        if let Some(ctx) = context {
            if !ctx.is_empty() {
                prompt = format!("{}\n\n【上下文】\n{}", prompt, ctx);
            }
        }

        // 2. 调用 AI Provider
        let payload = json!({
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.7,
            "max_tokens": 4096,
        });

        let resp = self
            .client
            .post(format!("{}/api/v1/ai/chat", self.ai_provider_url))
            .json(&payload)
            .send()
            .await
            .map_err(|e| format!("AI call failed: {}", e))?;

        let body: serde_json::Value = resp
            .json()
            .await
            .map_err(|e| format!("Parse failed: {}", e))?;

        let result = body["choices"][0]["message"]["content"]
            .as_str()
            .unwrap_or("")
            .to_string();

        let tokens = body["usage"]["total_tokens"].as_i64().unwrap_or(0) as i32;

        Ok((result, tokens))
    }
}
