use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use tracing::info;

type SharedState = Arc<Mutex<CanvasDb>>;

#[derive(Serialize, Deserialize, Clone)]
struct SceneNode {
    id: String,
    chapter_id: String,
    title: String,
    summary: String,
    characters: Vec<String>,
    location: String,
    mood: String,
    position: NodePosition,
}

#[derive(Serialize, Deserialize, Clone)]
struct NodePosition {
    x: f64,
    y: f64,
}

#[derive(Serialize, Deserialize, Clone)]
struct SceneEdge {
    source_id: String,
    target_id: String,
    relationship: String,
    strength: u32,
}

#[derive(Serialize)]
struct CanvasData {
    nodes: Vec<SceneNode>,
    edges: Vec<SceneEdge>,
}

struct CanvasDb {
    nodes: Vec<SceneNode>,
    edges: Vec<SceneEdge>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().with_env_filter("canvas=info").init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8091".to_string());
    let state: SharedState = Arc::new(Mutex::new(CanvasDb { nodes: vec![], edges: vec![] }));

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/canvas/nodes", post(create_node).get(list_nodes))
        .route("/api/v1/canvas/nodes/{id}", put(update_node))
        .route("/api/v1/canvas/edges", post(create_edge))
        .route("/api/v1/canvas/canvas/{chapter_id}", get(get_canvas))
        .route("/api/v1/canvas/layout", post(auto_layout))
        .with_state(state);

    info!("Canvas Service starting on :{}", port);
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "canvas-service"}))
}

async fn create_node(
    State(state): State<SharedState>,
    Json(mut n): Json<SceneNode>,
) -> Result<Json<SceneNode>, StatusCode> {
    n.id = uuid::Uuid::new_v4().to_string();
    state.lock().unwrap().nodes.push(n.clone());
    Ok(Json(n))
}

async fn list_nodes(
    State(state): State<SharedState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Json<Vec<SceneNode>> {
    let db = state.lock().unwrap();
    let chapter_id = params.get("chapter_id");
    Json(db.nodes.iter()
        .filter(|n| chapter_id.map_or(true, |c| n.chapter_id == *c))
        .cloned().collect())
}

async fn update_node(
    State(state): State<SharedState>,
    axum::extract::Path(id): axum::extract::Path<String>,
    Json(upd): Json<SceneNode>,
) -> Result<Json<SceneNode>, StatusCode> {
    let mut db = state.lock().unwrap();
    if let Some(n) = db.nodes.iter_mut().find(|n| n.id == id) {
        n.title = upd.title;
        n.summary = upd.summary;
        n.characters = upd.characters;
        n.location = upd.location;
        n.mood = upd.mood;
        n.position = upd.position;
        Ok(Json(n.clone()))
    } else {
        Err(StatusCode::NOT_FOUND)
    }
}

async fn create_edge(
    State(state): State<SharedState>,
    Json(e): Json<SceneEdge>,
) -> Json<SceneEdge> {
    state.lock().unwrap().edges.push(e.clone());
    Json(e)
}

async fn get_canvas(
    State(state): State<SharedState>,
    axum::extract::Path(chapter_id): axum::extract::Path<String>,
) -> Json<CanvasData> {
    let db = state.lock().unwrap();
    let nodes: Vec<SceneNode> = db.nodes.iter()
        .filter(|n| n.chapter_id == chapter_id).cloned().collect();
    let node_ids: std::collections::HashSet<String> = nodes.iter().map(|n| n.id.clone()).collect();
    let edges: Vec<SceneEdge> = db.edges.iter()
        .filter(|e| node_ids.contains(&e.source_id))
        .cloned().collect();
    Json(CanvasData { nodes, edges })
}

async fn auto_layout(
    State(state): State<SharedState>,
    Json(body): Json<serde_json::Value>,
) -> Result<Json<Vec<SceneNode>>, StatusCode> {
    let chapter_id = body["chapter_id"].as_str().ok_or(StatusCode::BAD_REQUEST)?;
    let mut db = state.lock().unwrap();
    let mut nodes: Vec<&mut SceneNode> = db.nodes.iter_mut()
        .filter(|n| n.chapter_id == chapter_id).collect();

    let total = nodes.len() as f64;
    let radius = 200.0;

    for (i, node) in nodes.iter_mut().enumerate() {
        let angle = (i as f64 / total) * std::f64::consts::TAU;
        node.position = NodePosition {
            x: radius * angle.cos(),
            y: radius * angle.sin(),
        };
    }

    Ok(Json(db.nodes.iter()
        .filter(|n| n.chapter_id == chapter_id)
        .cloned().collect()))
}