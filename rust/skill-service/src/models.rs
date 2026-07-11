use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// Skill 数据模型
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Skill {
    pub id: String,
    pub name: String,
    pub version: String,
    #[sqlx(rename = "type")]
    pub skill_type: String,  // style / writing / analysis / tool
    pub author: String,
    pub description: String,
    pub icon: String,
    pub prompt_template: String,
    pub variables: serde_json::Value,  // JSON map
    pub category: String,
    pub downloads: i32,
    pub rating: f32,
    pub source: String,      // local / marketplace
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// 执行请求
#[derive(Debug, Deserialize)]
pub struct ExecuteRequest {
    pub skill_id: String,
    pub variables: std::collections::HashMap<String, String>,
    pub context: Option<String>,
}

/// 执行响应
#[derive(Debug, Serialize)]
pub struct ExecuteResponse {
    pub result: String,
    pub skill_id: String,
    pub tokens_used: i32,
}

/// 蒸馏请求
#[derive(Debug, Deserialize)]
pub struct DistillRequest {
    pub text: String,
    pub name: String,
    pub author: Option<String>,
}

/// 蒸馏响应
#[derive(Debug, Serialize)]
pub struct DistillResponse {
    pub skill: Skill,
    pub skill_json: String,
}

/// Skill 列表响应
#[derive(Debug, Serialize)]
pub struct SkillListResponse {
    pub skills: Vec<Skill>,
    pub total: i32,
}
