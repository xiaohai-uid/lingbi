mod memory_service;

use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use memory_service::MemoryService;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::info;

#[derive(Clone)]
struct AppState {
    service: MemoryService,
}

// ── Embedding ──
#[derive(Deserialize)]
struct EmbedRequest {
    scene_id: String,
    text: String,
    world_id: String,
}

// ── Search ──
#[derive(Deserialize)]
struct SearchRequest {
    query: String,
    world_id: String,
    limit: Option<usize>,
}

#[derive(Serialize)]
struct SearchResult {
    id: String,
    score: f64,
    summary: String,
    scene_id: String,
}

#[derive(Serialize)]
struct SearchResponse {
    results: Vec<SearchResult>,
}

// ── Context ──
#[derive(Deserialize)]
struct ContextRequest {
    world_id: String,
    chapter_id: String,
    exclude_ids: Option<Vec<String>>,
}

#[derive(Serialize)]
struct ContextResponse {
    context: String,
    summary_count: usize,
}

// ── Summarize ──
#[derive(Deserialize)]
struct SummarizeRequest {
    scene_id: String,
    text: String,
    world_id: String,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| "memory=info".into()))
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8100".to_string());
    let ai_provider = std::env::var("AI_PROVIDER_URL")
        .unwrap_or_else(|_| "http://localhost:8081".to_string());
    let storage_url = std::env::var("STORAGE_SERVICE_URL")
        .unwrap_or_else(|_| "http://localhost:8089".to_string());

    let service = MemoryService::new(ai_provider, storage_url);
    let state = AppState { service };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/memory/embed", post(embed_handler))
        .route("/api/v1/memory/search", post(search_handler))
        .route("/api/v1/memory/context", post(context_handler))
        .route("/api/v1/memory/summarize", post(summarize_handler))
        .with_state(state);

    let addr: SocketAddr = format!("0.0.0.0:{}", port).parse().expect("Invalid port");
    info!("Memory Service starting on {}", addr);

    let listener = TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status":"ok","service":"memory-service","version":"0.1.0"}))
}

async fn embed_handler(
    State(state): State<AppState>,
    Json(req): Json<EmbedRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    state.service.embed_scene(&req.scene_id, &req.text, &req.world_id)
        .await
        .map(|id| Json(serde_json::json!({"status":"ok","embedding_id": id})))
        .map_err(|e| { tracing::error!("embed failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}

async fn search_handler(
    State(state): State<AppState>,
    Json(req): Json<SearchRequest>,
) -> Result<Json<SearchResponse>, StatusCode> {
    state.service.semantic_search(&req.query, &req.world_id, req.limit.unwrap_or(10))
        .await
        .map(|results| Json(SearchResponse { results }))
        .map_err(|e| { tracing::error!("search failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}

async fn context_handler(
    State(state): State<AppState>,
    Json(req): Json<ContextRequest>,
) -> Result<Json<ContextResponse>, StatusCode> {
    state.service.build_context(&req.world_id, &req.chapter_id, req.exclude_ids.as_deref())
        .await
        .map(|(context, count)| Json(ContextResponse { context, summary_count: count }))
        .map_err(|e| { tracing::error!("context failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}

async fn summarize_handler(
    State(state): State<AppState>,
    Json(req): Json<SummarizeRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    state.service.summarize_scene(&req.scene_id, &req.text, &req.world_id)
        .await
        .map(|summary| Json(serde_json::json!({"status":"ok","summary": summary})))
        .map_err(|e| { tracing::error!("summarize failed: {}", e); StatusCode::INTERNAL_SERVER_ERROR })
}
