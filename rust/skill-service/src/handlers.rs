use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{delete, get, post, put},
    Router,
};
use serde::Deserialize;
use uuid::Uuid;
use chrono::Utc;

use crate::executor::SkillExecutor;
use crate::models::*;
use crate::storage::SkillStorage;

/// 分页参数
#[derive(Deserialize)]
pub struct PaginationParams {
    page: Option<i64>,
    page_size: Option<i64>,
}

/// 应用状态
#[derive(Clone)]
pub struct AppState {
    pub storage: SkillStorage,
    pub executor: SkillExecutor,
}

/// 注册路由
pub fn routes(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/api/v1/skills", get(list_skills).post(create_skill))
        .route(
            "/api/v1/skills/{id}",
            get(get_skill).put(update_skill).delete(delete_skill),
        )
        .route("/api/v1/skills/{id}/execute", post(execute_skill))
        .route("/api/v1/skills/distill", post(distill_style))
        .with_state(state)
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "service": "skill-service",
        "version": "0.1.0"
    }))
}

async fn list_skills(
    State(state): State<AppState>,
    Query(params): Query<PaginationParams>,
) -> Result<Json<SkillListResponse>, StatusCode> {
    let page = params.page.unwrap_or(1);
    let page_size = params.page_size.unwrap_or(20);
    state
        .storage
        .list_skills(page, page_size)
        .await
        .map(Json)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}

async fn get_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<Skill>, StatusCode> {
    state
        .storage
        .get_skill(&id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .map(Json)
        .ok_or(StatusCode::NOT_FOUND)
}

async fn create_skill(
    State(state): State<AppState>,
    Json(mut skill): Json<Skill>,
) -> Result<(StatusCode, Json<Skill>), StatusCode> {
    skill.id = Uuid::new_v4().to_string();
    if skill.version.is_empty() {
        skill.version = "1.0.0".to_string();
    }
    if skill.source.is_empty() {
        skill.source = "local".to_string();
    }
    let now = Utc::now();
    skill.created_at = now;
    skill.updated_at = now;

    state
        .storage
        .create_skill(&skill)
        .await
        .map(|s| (StatusCode::CREATED, Json(s)))
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)
}

async fn update_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(skill): Json<Skill>,
) -> Result<Json<Skill>, StatusCode> {
    state
        .storage
        .update_skill(&id, &skill)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .map(Json)
        .ok_or(StatusCode::NOT_FOUND)
}

async fn delete_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    state
        .storage
        .delete_skill(&id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(serde_json::json!({"status": "deleted", "id": id})))
}

async fn execute_skill(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(req): Json<ExecuteRequest>,
) -> Result<Json<ExecuteResponse>, StatusCode> {
    let skill = state
        .storage
        .get_skill(&id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

    let (result, tokens) = state
        .executor
        .execute(&skill, &req.variables, req.context.as_deref())
        .await
        .map_err(|_| StatusCode::BAD_GATEWAY)?;

    Ok(Json(ExecuteResponse {
        result,
        skill_id: id,
        tokens_used: tokens,
    }))
}

async fn distill_style(
    Json(req): Json<DistillRequest>,
) -> Json<DistillResponse> {
    Json(crate::distiller::StyleDistiller::distill(req))
}
