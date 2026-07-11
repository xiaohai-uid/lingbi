use axum::{
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::info;

#[derive(Deserialize)]
struct AnalyzeRequest {
    world_id: String,
    trigger: TriggerEvent,
    characters: Vec<String>,
    existing_plot: Vec<String>,
}

#[derive(Deserialize, Clone)]
struct TriggerEvent {
    event: String,
    involved_characters: Vec<String>,
    impact_level: u32, // 1-5
}

#[derive(Serialize)]
struct ButterflyResult {
    immediate_effects: Vec<Effect>,
    chain_reactions: Vec<ChainReaction>,
    character_impacts: Vec<CharacterImpact>,
    changed_plot: Vec<String>,
}

#[derive(Serialize)]
struct Effect {
    description: String,
    probability: f64,
    severity: String,
}

#[derive(Serialize)]
struct ChainReaction {
    round: u32,
    effects: Vec<Effect>,
}

#[derive(Serialize)]
struct CharacterImpact {
    character: String,
    change: String,
    sentiment: String, // positive / negative / mixed
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().with_env_filter("butterfly=info").init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8096".to_string());

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/butterfly/analyze", post(analyze))
        .route("/api/v1/butterfly/what-if", post(what_if));

    info!("Butterfly Analyzer starting on :{}", port);
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "butterfly-analyzer"}))
}

async fn analyze(Json(req): Json<AnalyzeRequest>) -> Result<Json<ButterflyResult>, StatusCode> {
    let impact = req.trigger.impact_level.min(5).max(1);
    let char_count = req.characters.len();

    let immediate = vec![
        Effect {
            description: format!("{} 事件发生，{} 受到直接影响", req.trigger.event, req.trigger.involved_characters.join("、")),
            probability: 0.95,
            severity: if impact >= 4 { "critical".into() } else { "major".into() },
        },
        Effect {
            description: "其他角色开始关注此事件".to_string(),
            probability: 0.8,
            severity: "moderate".into(),
        },
    ];

    let chain = (1..=impact.min(3) as u32).map(|round| {
        let effects = match round {
            1 => vec![
                Effect { description: "次要角色立场开始分化".into(), probability: 0.7, severity: "moderate".into() },
                Effect { description: "事件引发新的矛盾".into(), probability: 0.6, severity: "moderate".into() },
            ],
            2 => vec![
                Effect { description: "长期盟友关系受到考验".into(), probability: 0.5, severity: "major".into() },
                Effect { description: "隐藏势力的介入".into(), probability: 0.4, severity: "major".into() },
            ],
            _ => vec![
                Effect { description: "世界格局发生变化".into(), probability: 0.3, severity: "critical".into() },
            ],
        };
        ChainReaction { round, effects }
    }).collect();

    let char_impacts: Vec<CharacterImpact> = req.characters.iter().take(5).map(|c| {
        let sentiment = if req.trigger.involved_characters.contains(c) { "mixed" } else { "positive" };
        CharacterImpact {
            character: c.clone(),
            change: format!("{} 因为 {} 事件而{}", c, req.trigger.event,
                if sentiment == "mixed" { "面临关键抉择" } else { "获得新的机遇" }),
            sentiment: sentiment.into(),
        }
    }).collect();

    let mut changed_plot = req.existing_plot.clone();
    changed_plot.push(format!("【蝴蝶效应】{}：{} → 影响 {} 个角色",
        req.trigger.event, &req.trigger.involved_characters.join("、"), char_count));

    Ok(Json(ButterflyResult {
        immediate_effects: immediate,
        chain_reactions: chain,
        character_impacts: char_impacts,
        changed_plot,
    }))
}

async fn what_if(Json(req): Json<serde_json::Value>) -> Json<serde_json::Value> {
    // "What if" scenario simulation
    let trigger = req["trigger"].as_str().unwrap_or("unknown");
    Json(serde_json::json!({
        "scenario": trigger,
        "probability": 0.45,
        "positive_outcomes": ["角色成长", "新盟友加入"],
        "negative_outcomes": ["关系破裂", "信任危机"],
        "recommendation": "此转折可能性中等，建议作为备选方案"
    }))
}