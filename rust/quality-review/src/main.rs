use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::info;

#[derive(Clone)]
struct AppState {
    ai_provider_url: String,
}

#[derive(Deserialize)]
struct ReviewRequest {
    chapter_id: Option<String>,
    content: String,
    world_id: Option<String>,
    genre: Option<String>,
    characters: Option<Vec<CharacterInfo>>,
}

#[derive(Deserialize)]
struct CharacterInfo {
    name: String,
    description: String,
}

#[derive(Serialize)]
struct ReviewReport {
    overall_score: f64,
    consistency: ConsistencyReport,
    hooks: HookAnalysis,
    style: StyleScore,
    issues: Vec<String>,
}

#[derive(Serialize)]
struct ConsistencyReport {
    score: f64,
    inconsistencies: Vec<String>,
}

#[derive(Serialize)]
struct HookAnalysis {
    density: f64,
    hooks: Vec<Hook>,
}

#[derive(Serialize)]
struct Hook {
    position: usize,
    r#type: String,
    intensity: u32,
}

#[derive(Serialize)]
struct StyleScore {
    grammar: f64,
    readability: f64,
    pacing: f64,
    suggestions: Vec<String>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("quality_review=info")
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8093".to_string());
    let ai_url = std::env::var("AI_PROVIDER_URL")
        .unwrap_or_else(|_| "http://ai-provider:8081".to_string());

    let state = AppState { ai_provider_url: ai_url };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/review/full", post(full_review))
        .route("/api/v1/review/consistency", post(check_consistency))
        .route("/api/v1/review/hooks", post(analyze_hooks))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    info!("Quality Review starting on {}", addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "quality-review"}))
}

async fn full_review(
    State(state): State<AppState>,
    Json(req): Json<ReviewRequest>,
) -> Result<Json<ReviewReport>, StatusCode> {
    let genre = req.genre.as_deref().unwrap_or("玄幻");

    // Calculate hook density
    let hook_analysis = analyze_hooks_internal(&req.content, genre);

    // Consistency check
    let consistency = if let Some(chars) = &req.characters {
        check_consistency_internal(&req.content, chars)
    } else {
        ConsistencyReport { score: 1.0, inconsistencies: vec![] }
    };

    // Style analysis
    let style = analyze_style(&req.content);

    // Overall score
    let overall = (consistency.score * 0.4 + hook_analysis.density.min(1.0) * 0.3 + style.grammar * 0.3).min(1.0);

    let mut issues = Vec::new();
    if consistency.score < 0.7 {
        issues.push(format!("人设一致性偏低 ({:.1}%)", consistency.score * 100.0));
    }
    if hook_analysis.density < 0.3 {
        issues.push("爽点密度不足".to_string());
    }
    if style.grammar < 0.8 {
        issues.push("语法/句式可优化".to_string());
    }

    Ok(Json(ReviewReport {
        overall_score: (overall * 100.0).round() / 100.0,
        consistency,
        hooks: hook_analysis,
        style,
        issues,
    }))
}

async fn check_consistency(
    State(state): State<AppState>,
    Json(req): Json<ReviewRequest>,
) -> Result<Json<ConsistencyReport>, StatusCode> {
    let chars = req.characters.unwrap_or_default();
    Ok(Json(check_consistency_internal(&req.content, &chars)))
}

async fn analyze_hooks(
    State(state): State<AppState>,
    Json(req): Json<ReviewRequest>,
) -> Result<Json<HookAnalysis>, StatusCode> {
    let genre = req.genre.as_deref().unwrap_or("玄幻");
    Ok(Json(analyze_hooks_internal(&req.content, genre)))
}

fn check_consistency_internal(content: &str, characters: &[CharacterInfo]) -> ConsistencyReport {
    let mut issues = Vec::new();
    for char_info in characters {
        let name_count = content.matches(&char_info.name).count();
        let desc_words: Vec<&str> = char_info.description.split_whitespace().collect();
        let matched = desc_words.iter().filter(|w| content.contains(**w)).count();
        let match_ratio = if desc_words.is_empty() { 1.0 } else { matched as f64 / desc_words.len() as f64 };

        if match_ratio < 0.3 && name_count > 0 {
            issues.push(format!("{} 的描述特征在正文中体现不足 ({:.0}%)", char_info.name, match_ratio * 100.0));
        }
    }

    let score = if characters.is_empty() { 1.0 } else {
        (issues.len() as f64 / characters.len() as f64).max(0.0).min(1.0)
    };

    ConsistencyReport { score: 1.0 - score, inconsistencies: issues }
}

fn analyze_hooks_internal(content: &str, genre: &str) -> HookAnalysis {
    let hook_keywords = match genre {
        "玄幻" | "修仙" => &["突然", "竟然", "震怒", "震惊", "突破", "发现", "秘密", "宝藏"][..],
        "都市" | "现代" => &["意外", "相遇", "冲突", "危机", "转机", "秘密"][..],
        "悬疑" | "推理" => &["线索", "真相", "谜团", "死者", "嫌疑人", "证据"][..],
        _ => &["突然", "但是", "然而", "意外", "震惊", "关键"][..],
    };

    let lines: Vec<&str> = content.lines().collect();
    let mut hooks = Vec::new();
    let mut total_hooks = 0;

    for (i, line) in lines.iter().enumerate() {
        for kw in hook_keywords {
            if line.contains(kw) {
                total_hooks += 1;
                hooks.push(Hook {
                    position: i + 1,
                    r#type: kw.to_string(),
                    intensity: (line.len() as u32 / 50).max(1).min(5),
                });
                break;
            }
        }
    }

    let word_count = content.split_whitespace().count();
    let density = if word_count > 0 {
        (total_hooks as f64 / word_count as f64 * 500.0).min(1.0)
    } else {
        0.0
    };

    HookAnalysis { density: (density * 100.0).round() / 100.0, hooks }
}

fn analyze_style(content: &str) -> StyleScore {
    let total_chars = content.chars().count() as f64;
    let sentences: Vec<&str> = content.split(|c: char| c == '。' || c == '！' || c == '？').collect();
    let avg_sentence_len = if sentences.len() > 0 {
        content.len() as f64 / sentences.len() as f64
    } else {
        50.0
    };

    let readability = if avg_sentence_len > 80.0 { 0.4 }
        else if avg_sentence_len > 50.0 { 0.6 }
        else { 0.9 };

    let mut suggestions = Vec::new();
    if avg_sentence_len > 80.0 {
        suggestions.push("句子偏长，建议适当拆分".to_string());
    }
    if total_chars < 500.0 {
        suggestions.push("章节篇幅较短，建议充实内容".to_string());
    }

    StyleScore {
        grammar: 0.85,
        readability,
        pacing: 0.75,
        suggestions,
    }
}