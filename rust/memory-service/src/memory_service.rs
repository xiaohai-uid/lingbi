use reqwest::Client;
use serde_json::json;
use uuid::Uuid;

/// Memory Service — 向量嵌入 + 语义搜索 + 上下文构建 + 摘要
#[derive(Clone)]
pub struct MemoryService {
    ai_provider_url: String,
    storage_url: String,
    client: Client,
}

impl MemoryService {
    pub fn new(ai_provider_url: String, storage_url: String) -> Self {
        Self {
            ai_provider_url,
            storage_url,
            client: Client::new(),
        }
    }

    /// 生成 embedding 并存入 Qdrant
    pub async fn embed_scene(
        &self,
        scene_id: &str,
        text: &str,
        world_id: &str,
    ) -> Result<String, String> {
        // 1. 调用 AI Provider 生成 embedding
        let embed_resp = self.client
            .post(format!("{}/api/v1/ai/embed", self.ai_provider_url))
            .json(&json!({ "text": text }))
            .send()
            .await
            .map_err(|e| format!("AI Provider call failed: {}", e))?;

        let embed_body: serde_json::Value = embed_resp
            .json().await
            .map_err(|e| format!("Parse failed: {}", e))?;

        let vector: Vec<f64> = embed_body["embedding"]
            .as_array()
            .ok_or("No embedding in response")?
            .iter()
            .map(|v| v.as_f64().unwrap_or(0.0))
            .collect();

        // 2. 存储到 Qdrant (通过 Storage Service)
        let embedding_id = Uuid::new_v4().to_string();
        let upsert_payload = json!({
            "collection": "memory_summaries",
            "id": embedding_id,
            "vector": vector,
            "payload": {
                "scene_id": scene_id,
                "world_id": world_id,
                "summary": text.chars().take(200).collect::<String>(),
            }
        });

        self.client
            .post(format!("{}/api/v1/storage/upsert", self.storage_url))
            .json(&upsert_payload)
            .send()
            .await
            .map_err(|e| format!("Storage upsert failed: {}", e))?;

        Ok(embedding_id)
    }

    /// 语义搜索
    pub async fn semantic_search(
        &self,
        query: &str,
        world_id: &str,
        limit: usize,
    ) -> Result<Vec<super::SearchResult>, String> {
        // 1. 对查询文本生成 embedding
        let embed_resp = self.client
            .post(format!("{}/api/v1/ai/embed", self.ai_provider_url))
            .json(&json!({ "text": query }))
            .send()
            .await
            .map_err(|e| format!("AI embed failed: {}", e))?;

        let embed_body: serde_json::Value = embed_resp
            .json().await
            .map_err(|e| format!("Parse failed: {}", e))?;

        let vector: Vec<f64> = embed_body["embedding"]
            .as_array()
            .ok_or("No embedding")?
            .iter()
            .map(|v| v.as_f64().unwrap_or(0.0))
            .collect();

        // 2. 搜索 Qdrant
        let search_resp = self.client
            .post(format!("{}/api/v1/storage/search", self.storage_url))
            .json(&json!({
                "collection": "memory_summaries",
                "vector": vector,
                "limit": limit,
            }))
            .send()
            .await
            .map_err(|e| format!("Storage search failed: {}", e))?;

        let search_body: serde_json::Value = search_resp
            .json().await
            .map_err(|e| format!("Parse failed: {}", e))?;

        // 3. 解析结果
        let results = search_body["results"]
            .as_array()
            .map(|arr| {
                arr.iter().map(|item| {
                    let payload = &item["payload"];
                    super::SearchResult {
                        id: item["id"].as_str().unwrap_or("").to_string(),
                        score: item["score"].as_f64().unwrap_or(0.0),
                        summary: payload["summary"].as_str().unwrap_or("").to_string(),
                        scene_id: payload["scene_id"].as_str().unwrap_or("").to_string(),
                    }
                }).collect::<Vec<_>>()
            })
            .unwrap_or_default();

        Ok(results)
    }

    /// 构建记忆上下文
    pub async fn build_context(
        &self,
        _world_id: &str,
        _chapter_id: &str,
        _exclude_ids: Option<&[String]>,
    ) -> Result<(String, usize), String> {
        // 从 Qdrant 检索前序场景摘要 + 格式化
        // 简化版：返回提示性文字
        let context = "【记忆上下文 — 由 Memory Service 构建】\n\n".to_string();
        Ok((context, 0))
    }

    /// 对场景正文做 LLM 摘要
    pub async fn summarize_scene(
        &self,
        _scene_id: &str,
        text: &str,
        _world_id: &str,
    ) -> Result<String, String> {
        let prompt = format!(
            "你是一个专业的小说摘要助手。\n分析以下场景正文，输出 JSON 格式结构化摘要。\n\n场景正文：\n{}\n\n输出格式：\n{{\"summary\":\"200-500字摘要\",\"keywords\":[],\"mood\":\"\",\"conflictType\":\"\"}}",
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
        let result = body["choices"][0]["message"]["content"]
            .as_str()
            .unwrap_or("")
            .to_string();

        Ok(result)
    }
}
