mod style_analyzer;

use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::info;
use style_analyzer::StyleAnalyzer;

#[derive(Clone)]
struct AppState {
    analyzer: StyleAnalyzer,
}

#[derive(Deserialize)]
struct AnalyzeRequest {
    scene_id: String,
    text: String,
    world_id: String,
}

#[derive(Serialize)]
struct AnalyzeResponse {
    summary: String,
    tone: String,
    vocabulary_level: String,
    dialogue_ratio: f64,
    sentence_complexity: f64,
    pacing: String,
    keywords: Vec<String>,
}

#[derive(Deserialize)]
struct DriftRequest {
    text_a: String,
    text_b: String,
}

#[derive(Serialize)]
struct DriftResponse {
    drift_score: f64,
    drifted_dimensions: Vec<String>,
    details: String,
    suggestions: String,
}

#[derive(Deserialize)]
struct ContextRequest {
    world_id: String,
    chapter_id: Option<String>,
    work_id: Option<String>,
}

#[derive(Serialize)]
struct ContextResponse {
    context: String,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "style=info".into()))
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8101".to_string());
    let ai_provider = std::env::var("AI_PROVIDER_URL")
        .unwrap_or_else(|_| "http://localhost:8081".to_string());

    let analyzer = StyleAnalyzer::new(ai_provider);
    let state = AppState { analyzer };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/style/analyze", post(analyze_handler))
        .route("/api/v1/style/drift", post(drift_handler))
        .route("/api/v1/style/context", post(context_handler))
        .with_state(state);

    let addr: SocketAddr = format!("0.0.0.0:{}", port).parse().expect("Invalid port");
    info!("Style Service starting on {}", addr);

    let listener = TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status":"ok","service":"style-service","version":"0.1.0"}))
}

async fn analyze_handler(
    State(state): State<AppState>,
    Json(req): Json<AnalyzeRequest>,
) -> Result<Json<AnalyzeResponse>, StatusCode> {
    state.analyzer.analyze(&req.text)
        .await
        .map(Json)
        .map_err(|e| { tracing::error!("analyze failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}

async fn drift_handler(
    State(state): State<AppState>,
    Json(req): Json<DriftRequest>,
) -> Result<Json<DriftResponse>, StatusCode> {
    state.analyzer.detect_drift(&req.text_a, &req.text_b)
        .await
        .map(Json)
        .map_err(|e| { tracing::error!("drift failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}

async fn context_handler(
    State(state): State<AppState>,
    Json(req): Json<ContextRequest>,
) -> Result<Json<ContextResponse>, StatusCode> {
    let tone = "serious".to_string();
    let vocab = "literary".to_string();
    let pacing = "balanced".to_string();
    let ctx = state.analyzer.build_style_context(&tone, &vocab, &pacing);
    Ok(Json(ContextResponse { context: ctx }))
}
