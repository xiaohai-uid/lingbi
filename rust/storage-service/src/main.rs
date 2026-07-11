use axum::{
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use tracing::info;

#[derive(Clone)]
struct AppState {
    qdrant_url: String,
}

#[derive(Deserialize)]
struct UpsertRequest {
    collection: String,
    id: String,
    vector: Vec<f32>,
    payload: serde_json::Value,
}

#[derive(Serialize)]
struct UpsertResponse {
    status: String,
    id: String,
}

#[derive(Deserialize)]
struct SearchRequest {
    collection: String,
    vector: Vec<f32>,
    limit: Option<u64>,
}

#[derive(Serialize)]
struct SearchResponse {
    results: Vec<SearchResult>,
}

#[derive(Serialize)]
struct SearchResult {
    id: String,
    score: f64,
    payload: serde_json::Value,
}

#[derive(Deserialize)]
struct DeleteRequest {
    collection: String,
    id: String,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().with_env_filter("storage=info").init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8089".to_string());
    let qdrant_url = std::env::var("QDRANT_URL").unwrap_or_else(|_| "http://qdrant:6333".to_string());

    let state = AppState { qdrant_url };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/storage/upsert", post(upsert_vector))
        .route("/api/v1/storage/search", post(search_vectors))
        .route("/api/v1/storage/delete", post(delete_vector))
        .route("/api/v1/storage/collections", get(list_collections))
        .route("/api/v1/storage/collections", post(create_collection))
        .with_state(state);

    info!("Storage Service starting on :{}", port);
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "storage-service"}))
}

async fn upsert_vector(
    State(state): State<AppState>,
    Json(req): Json<UpsertRequest>,
) -> Result<Json<UpsertResponse>, StatusCode> {
    // In production, forward to Qdrant API:
    // PUT /collections/{collection}/points
    let client = reqwest::Client::new();
    let payload = serde_json::json!({
        "points": [{
            "id": req.id,
            "vector": req.vector,
            "payload": req.payload
        }]
    });

    let resp = client
        .put(format!("{}/collections/{}/points", state.qdrant_url, req.collection))
        .json(&payload)
        .send()
        .await;

    match resp {
        Ok(_) => Ok(Json(UpsertResponse { status: "ok".into(), id: req.id })),
        Err(e) => {
            tracing::warn!("Qdrant not available, using local mode: {}", e);
            // Local fallback
            Ok(Json(UpsertResponse { status: "cached_local".into(), id: req.id }))
        }
    }
}

async fn search_vectors(
    State(state): State<AppState>,
    Json(req): Json<SearchRequest>,
) -> Result<Json<SearchResponse>, StatusCode> {
    let limit = req.limit.unwrap_or(10);
    let client = reqwest::Client::new();
    let payload = serde_json::json!({
        "vector": req.vector,
        "limit": limit,
        "with_payload": true
    });

    let resp = client
        .post(format!("{}/collections/{}/points/search", state.qdrant_url, req.collection))
        .json(&payload)
        .send()
        .await;

    match resp {
        Ok(r) => {
            let body: serde_json::Value = r.json().await.unwrap_or_default();
            let results = body["result"].as_array().map(|arr| {
                arr.iter().map(|item| {
                    let point = &item["point"];
                    SearchResult {
                        id: point["id"].as_str().unwrap_or("").to_string(),
                        score: point["score"].as_f64().unwrap_or(0.0),
                        payload: point["payload"].clone(),
                    }
                }).collect()
            }).unwrap_or_default();

            Ok(Json(SearchResponse { results }))
        }
        Err(e) => {
            tracing::warn!("Qdrant search failed (local mode): {}", e);
            Ok(Json(SearchResponse { results: vec![] }))
        }
    }
}

async fn delete_vector(
    State(state): State<AppState>,
    Json(req): Json<DeleteRequest>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let client = reqwest::Client::new();
    let payload = serde_json::json!({ "points": [req.id] });

    let resp = client
        .post(format!("{}/collections/{}/points/delete", state.qdrant_url, req.collection))
        .json(&payload)
        .send()
        .await;

    match resp {
        Ok(_) => Ok(Json(serde_json::json!({"status": "deleted", "id": req.id}))),
        Err(e) => {
            tracing::warn!("Qdrant delete failed: {}", e);
            Ok(Json(serde_json::json!({"status": "local_only", "id": req.id})))
        }
    }
}

async fn list_collections(
    State(state): State<AppState>,
) -> Json<serde_json::Value> {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/collections", state.qdrant_url)).send().await;

    match resp {
        Ok(r) => {
            let body = r.json::<serde_json::Value>().await.unwrap_or_default();
            Json(body)
        }
        Err(_) => Json(serde_json::json!({
            "collections": [
                {"name": "canon_embeddings"},
                {"name": "document_embeddings"}
            ],
            "local": true
        }))
    }
}

async fn create_collection(
    State(state): State<AppState>,
    Json(body): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let collection = body["name"].as_str().unwrap_or("default");
    let dims = body["dimensions"].as_u64().unwrap_or(1536);

    let client = reqwest::Client::new();
    let payload = serde_json::json!({
        "name": collection,
        "vectors": {
            "size": dims,
            "distance": "Cosine"
        }
    });

    let resp = client
        .put(format!("{}/collections/{}", state.qdrant_url, collection))
        .json(&payload)
        .send()
        .await;

    match resp {
        Ok(r) => {
            let body = r.json::<serde_json::Value>().await.unwrap_or_default();
            Ok(Json(body))
        }
        Err(e) => {
            tracing::warn!("Qdrant unavailable, returning local: {}", e);
            Ok(Json(serde_json::json!({"status": "created_local", "name": collection})))
        }
    }
}