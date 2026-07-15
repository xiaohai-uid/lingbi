use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
    routing::{get, delete, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use tracing::info;

type SharedState = Arc<Mutex<CanonDb>>;

#[derive(Serialize, Deserialize, Clone)]
struct Character {
    id: String,
    world_id: String,
    name: String,
    description: String,
    identities: Vec<Identity>,
    arc: String,
    weight: u32,
}

#[derive(Serialize, Deserialize, Clone)]
struct Identity {
    id: String,
    character_id: String,
    name: String,
    period: String,
    description: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct Location {
    id: String,
    world_id: String,
    name: String,
    description: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct Lore {
    id: String,
    world_id: String,
    title: String,
    content: String,
    category: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct WorldRule {
    id: String,
    world_id: String,
    name: String,
    description: String,
    scope: String,
}

#[derive(Serialize, Deserialize, Clone)]
struct CharacterEdge {
    source_id: String,
    target_id: String,
    r#type: String,
    strength: u32,
}

#[derive(Serialize, Clone)]
struct CharacterGraph {
    characters: Vec<Character>,
    edges: Vec<CharacterEdge>,
}

struct CanonDb {
    characters: Vec<Character>,
    locations: Vec<Location>,
    lores: Vec<Lore>,
    rules: Vec<WorldRule>,
    edges: Vec<CharacterEdge>,
}

impl CanonDb {
    fn new() -> Self {
        Self {
            characters: vec![],
            locations: vec![],
            lores: vec![],
            rules: vec![],
            edges: vec![],
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().with_env_filter("canon_service=info").init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8084".to_string());
    let state: SharedState = Arc::new(Mutex::new(CanonDb::new()));

    let app = Router::new()
        .route("/health", get(health))
        // Characters
        .route("/api/v1/canon/characters", post(create_character).get(list_characters))
        .route("/api/v1/canon/characters/{id}", get(get_character).put(update_character).delete(delete_character))
        // Locations
        .route("/api/v1/canon/locations", post(create_location).get(list_locations))
        // Lores
        .route("/api/v1/canon/lores", post(create_lore).get(list_lores))
        // Rules
        .route("/api/v1/canon/rules", post(create_rule).get(list_rules))
        // Graph
        .route("/api/v1/canon/graph/{world_id}", get(get_graph))
        .route("/api/v1/canon/edges", post(add_edge))
        .route("/api/v1/canon/edges/{source_id}/{target_id}", delete(remove_edge))
        .with_state(state);

    info!("Canon Service starting on :{}", port);
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "canon-service"}))
}

// ---- Characters ----

async fn create_character(
    State(state): State<SharedState>,
    Json(mut c): Json<Character>,
) -> Result<Json<Character>, StatusCode> {
    c.id = uuid::Uuid::new_v4().to_string();
    let mut db = state.lock().unwrap();
    db.characters.push(c.clone());
    Ok(Json(c))
}

async fn get_character(
    State(state): State<SharedState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> Result<Json<Character>, StatusCode> {
    let db = state.lock().unwrap();
    db.characters.iter().find(|c| c.id == id)
        .cloned()
        .ok_or(StatusCode::NOT_FOUND)
        .map(Json)
}

async fn list_characters(
    State(state): State<SharedState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Json<Vec<Character>> {
    let db = state.lock().unwrap();
    let world_id = params.get("world_id");
    let chars: Vec<Character> = db.characters.iter()
        .filter(|c| world_id.map_or(true, |w| c.world_id == *w))
        .cloned()
        .collect();
    Json(chars)
}

async fn update_character(
    State(state): State<SharedState>,
    axum::extract::Path(id): axum::extract::Path<String>,
    Json(upd): Json<Character>,
) -> Result<Json<Character>, StatusCode> {
    let mut db = state.lock().unwrap();
    if let Some(c) = db.characters.iter_mut().find(|c| c.id == id) {
        c.name = upd.name;
        c.description = upd.description;
        c.arc = upd.arc;
        c.weight = upd.weight;
        c.identities = upd.identities;
        Ok(Json(c.clone()))
    } else {
        Err(StatusCode::NOT_FOUND)
    }
}

async fn delete_character(
    State(state): State<SharedState>,
    axum::extract::Path(id): axum::extract::Path<String>,
) -> StatusCode {
    let mut db = state.lock().unwrap();
    if let Some(pos) = db.characters.iter().position(|c| c.id == id) {
        db.characters.remove(pos);
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

// ---- Locations ----

async fn create_location(
    State(state): State<SharedState>,
    Json(mut l): Json<Location>,
) -> Result<Json<Location>, StatusCode> {
    l.id = uuid::Uuid::new_v4().to_string();
    state.lock().unwrap().locations.push(l.clone());
    Ok(Json(l))
}

async fn list_locations(
    State(state): State<SharedState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Json<Vec<Location>> {
    let db = state.lock().unwrap();
    let world_id = params.get("world_id");
    Json(db.locations.iter()
        .filter(|l| world_id.map_or(true, |w| l.world_id == *w))
        .cloned()
        .collect())
}

// ---- Lores ----

async fn create_lore(
    State(state): State<SharedState>,
    Json(mut l): Json<Lore>,
) -> Result<Json<Lore>, StatusCode> {
    l.id = uuid::Uuid::new_v4().to_string();
    state.lock().unwrap().lores.push(l.clone());
    Ok(Json(l))
}

async fn list_lores(
    State(state): State<SharedState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Json<Vec<Lore>> {
    let db = state.lock().unwrap();
    let world_id = params.get("world_id");
    Json(db.lores.iter()
        .filter(|l| world_id.map_or(true, |w| l.world_id == *w))
        .cloned()
        .collect())
}

// ---- Rules ----

async fn create_rule(
    State(state): State<SharedState>,
    Json(mut r): Json<WorldRule>,
) -> Result<Json<WorldRule>, StatusCode> {
    r.id = uuid::Uuid::new_v4().to_string();
    state.lock().unwrap().rules.push(r.clone());
    Ok(Json(r))
}

async fn list_rules(
    State(state): State<SharedState>,
    axum::extract::Query(params): axum::extract::Query<std::collections::HashMap<String, String>>,
) -> Json<Vec<WorldRule>> {
    let db = state.lock().unwrap();
    let world_id = params.get("world_id");
    Json(db.rules.iter()
        .filter(|r| world_id.map_or(true, |w| r.world_id == *w))
        .cloned()
        .collect())
}

// ---- Graph ----

async fn get_graph(
    State(state): State<SharedState>,
    axum::extract::Path(world_id): axum::extract::Path<String>,
) -> Json<CharacterGraph> {
    let db = state.lock().unwrap();
    let chars: Vec<Character> = db.characters.iter()
        .filter(|c| c.world_id == world_id).cloned().collect();
    let char_ids: std::collections::HashSet<String> = chars.iter().map(|c| c.id.clone()).collect();
    let edges: Vec<CharacterEdge> = db.edges.iter()
        .filter(|e| char_ids.contains(&e.source_id))
        .cloned().collect();

    Json(CharacterGraph { characters: chars, edges })
}

async fn add_edge(
    State(state): State<SharedState>,
    Json(e): Json<CharacterEdge>,
) -> Result<Json<CharacterEdge>, StatusCode> {
    let mut db = state.lock().unwrap();
    if !db.characters.iter().any(|c| c.id == e.source_id) || !db.characters.iter().any(|c| c.id == e.target_id) {
        return Err(StatusCode::BAD_REQUEST);
    }
    db.edges.push(e.clone());
    Ok(Json(e))
}

async fn remove_edge(
    State(state): State<SharedState>,
    axum::extract::Path((sid, tid)): axum::extract::Path<(String, String)>,
) -> StatusCode {
    let mut db = state.lock().unwrap();
    if let Some(pos) = db.edges.iter().position(|e| e.source_id == sid && e.target_id == tid) {
        db.edges.remove(pos);
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}