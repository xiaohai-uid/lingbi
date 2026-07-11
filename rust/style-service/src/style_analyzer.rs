use reqwest::Client;
use serde_json::json;

#[derive(Clone)]
pub struct StyleAnalyzer {
    ai_provider_url: String,
    client: Client,
}

impl StyleAnalyzer {
    pub fn new(ai_provider_url: String) -> Self {
        Self {
            ai_provider_url,
            client: Client::new(),
        }
    }

    /// 分析文本风格
    pub async fn analyze(&self, text: &str) -> Result<super::AnalyzeResponse, String> {
        let prompt = format!(
            r#"你是一个专业的文学风格分析专家。
分析以下文本的写作风格，输出 JSON。

输出格式：
{{
  "summary": "一句话风格概述",
  "tone": "serious/light/humorous/heavy/mysterious",
  "vocabularyLevel": "casual/literary/classical/colloquial",
  "dialogueRatio": 0.0-1.0,
  "sentenceComplexity": 0.0-1.0,
  "pacing": "fast/balanced/slow",
  "keywords": ["关键词1", "关键词2"]
}}

文本：
{}"#,
            text
        );

        let resp = self.client
            .post(format!("{}/api/v1/ai/chat", self.ai_provider_url))
            .json(&json!({
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.3,
                "max_tokens": 2048,
            }))
            .send()
            .await
            .map_err(|e| format!("AI call failed: {}", e))?;

        let body: serde_json::Value = resp.json().await.map_err(|e| format!("Parse failed: {}", e))?;
        let content = body["choices"][0]["message"]["content"]
            .as_str().unwrap_or("{}");

        let parsed: serde_json::Value = serde_json::from_str(content)
            .map_err(|e| format!("JSON parse failed: {}", e))?;

        Ok(super::AnalyzeResponse {
            summary: parsed["summary"].as_str().unwrap_or("").to_string(),
            tone: parsed["tone"].as_str().unwrap_or("serious").to_string(),
            vocabulary_level: parsed["vocabularyLevel"].as_str().unwrap_or("literary").to_string(),
            dialogue_ratio: parsed["dialogueRatio"].as_f64().unwrap_or(0.3),
            sentence_complexity: parsed["sentenceComplexity"].as_f64().unwrap_or(0.5),
            pacing: parsed["pacing"].as_str().unwrap_or("balanced").to_string(),
            keywords: parsed["keywords"].as_array().map(|a|
                a.iter().filter_map(|v| v.as_str().map(String::from)).collect()
            ).unwrap_or_default(),
        })
    }

    /// 检测风格漂移
    pub async fn detect_drift(&self, text_a: &str, text_b: &str) -> Result<super::DriftResponse, String> {
        let prompt = format!(
            r#"你是一个专业的文学风格一致性检测专家。
比较以下两段文本的风格差异，输出 JSON。

输出格式：
{{
  "driftScore": 0.0-1.0,
  "driftedDimensions": ["tone", "vocabularyLevel"],
  "details": "差异描述",
  "suggestions": "修正建议"
}}

文本A：
{}

文本B：
{}"#,
            text_a, text_b
        );

        let resp = self.client
            .post(format!("{}/api/v1/ai/chat", self.ai_provider_url))
            .json(&json!({
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.3,
                "max_tokens": 1024,
            }))
            .send()
            .await
            .map_err(|e| format!("AI call failed: {}", e))?;

        let body: serde_json::Value = resp.json().await.map_err(|e| format!("Parse failed: {}", e))?;
        let content = body["choices"][0]["message"]["content"]
            .as_str().unwrap_or("{}");

        let parsed: serde_json::Value = serde_json::from_str(content).unwrap_or(json!({}));

        Ok(super::DriftResponse {
            drift_score: parsed["driftScore"].as_f64().unwrap_or(0.0),
            drifted_dimensions: parsed["driftedDimensions"].as_array().map(|a|
                a.iter().filter_map(|v| v.as_str().map(String::from)).collect()
            ).unwrap_or_default(),
            details: parsed["details"].as_str().unwrap_or("").to_string(),
            suggestions: parsed["suggestions"].as_str().unwrap_or("").to_string(),
        })
    }

    /// 构建风格上下文（用于生成时注入）
    pub fn build_style_context(&self, tone: &str, vocabulary: &str, pacing: &str) -> String {
        format!(
            "【风格指南】\n语调：{}\n词汇层次：{}\n节奏：{}",
            tone, vocabulary, pacing
        )
    }
}
