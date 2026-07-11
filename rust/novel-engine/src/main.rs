use axum::{
    extract::State,
    http::StatusCode,
    response::{sse::Event, Json, Sse},
    routing::{get, post},
    Router,
};
use futures::stream::Stream;
use serde::{Deserialize, Serialize};
use std::convert::Infallible;
use tera::Tera;
use tracing::info;

struct AppState {
    http_client: reqwest::Client,
    ai_provider_url: String,
    templates: Tera,
}

// ---- 数据模型 ----

#[derive(Deserialize)]
struct Layer1Request {
    user_idea: String,
    genre: Option<String>,
    style: Option<String>,
    num_characters: Option<u32>,
}

#[derive(Serialize)]
struct SynopsisAndCharacters {
    synopsis: String,
    characters: Vec<CharacterBrief>,
}

#[derive(Serialize, Deserialize)]
struct CharacterBrief {
    name: String,
    role: String,
    description: String,
    arc: String,
}

#[derive(Deserialize)]
struct Layer2Request {
    synopsis: String,
    characters: Vec<CharacterBrief>,
    chapter_count: Option<u32>,
}

#[derive(Serialize)]
struct ChapterOutline {
    chapters: Vec<ChapterSummary>,
}

#[derive(Serialize, Deserialize)]
struct ChapterSummary {
    title: String,
    summary: String,
    characters: Vec<String>,
    location: String,
    mood: String,
    conflict: String,
}

#[derive(Deserialize)]
struct StreamLayer3Request {
    scene: SceneOutline,
    synopsis: String,
    character_context: String,
    chapter_context: String,
}

#[derive(Deserialize)]
struct SceneOutline {
    title: String,
    summary: String,
    characters: Vec<String>,
    location: String,
    mood: String,
    conflict: String,
}

#[derive(Deserialize)]
struct ContinueRequest {
    text: String,
    context: String,
    max_new_tokens: Option<u32>,
}

// ---- Prompt 模板 ----

const LAYER1_PROMPT: &str = r#"你是一位资深网文编辑。根据用户的创意，生成故事梗概和核心人设。

用户创意：{{ idea }}
题材：{{ genre }}
风格：{{ style }}

请以JSON格式返回：
{
  "synopsis": "300字以内的故事梗概",
  "characters": [
    {"name": "角色名", "role": "主角/配角/反派", "description": "角色描述", "arc": "成长弧线"}
  ]
}"#;

const LAYER2_PROMPT: &str = r#"根据以下故事梗概和人设，生成详细的章节细纲。

梗概：{{ synopsis }}
人设：{{ characters }}
章节数：{{ chapter_count }}

请以JSON格式返回：
{
  "chapters": [
    {
      "title": "章节标题",
      "summary": "章节概要",
      "characters": ["出场角色"],
      "location": "场景地点",
      "mood": "氛围",
      "conflict": "核心冲突"
    }
  ]
}"#;

const LAYER3_PROMPT: &str = r#"根据章节细纲和场景描述，写出这一场景的正文。

梗概：{{ synopsis }}
角色背景：{{ character_context }}
章节上下文：{{ chapter_context }}

场景：{{ scene_title }}
概要：{{ scene_summary }}
出场角色：{{ scene_characters }}
地点：{{ scene_location }}
氛围：{{ mood }}
冲突：{{ conflict }}

请写出流畅的中文小说正文，约800-1500字。"#;

// ---- Main ----

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("novel_engine=info,tower_http=info")
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8092".to_string());
    let ai_url = std::env::var("AI_PROVIDER_URL")
        .unwrap_or_else(|_| "http://ai-provider:8081".to_string());

    let mut tera = Tera::default();
    tera.add_raw_template("layer1", LAYER1_PROMPT)
        .expect("failed to add layer1 template");
    tera.add_raw_template("layer2", LAYER2_PROMPT)
        .expect("failed to add layer2 template");
    tera.add_raw_template("layer3", LAYER3_PROMPT)
        .expect("failed to add layer3 template");

    let state = AppState {
        http_client: reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(180))
            .build()
            .expect("failed to build client"),
        ai_provider_url: ai_url,
        templates: tera,
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/novel/generate-layer1", post(generate_layer1))
        .route("/api/v1/novel/generate-layer2", post(generate_layer2))
        .route("/api/v1/novel/stream-layer3", post(stream_layer3))
        .route("/api/v1/novel/continue", post(continue_writing))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    info!("Novel Engine starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");

    axum::serve(listener, app)
        .await
        .expect("server error");
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "novel-engine"}))
}

async fn generate_layer1(
    State(state): State<AppState>,
    Json(req): Json<Layer1Request>,
) -> Result<Json<SynopsisAndCharacters>, StatusCode> {
    let mut ctx = tera::Context::new();
    ctx.insert("idea", &req.user_idea);
    ctx.insert("genre", &req.genre.as_deref().unwrap_or("玄幻"));
    ctx.insert("style", &req.style.as_deref().unwrap_or("qidian"));

    let prompt = state.templates.render("layer1", &ctx)
        .map_err(|e| {
            tracing::error!("Template error: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let result = call_llm_structured::<SynopsisAndCharacters>(
        &state.http_client,
        &state.ai_provider_url,
        "网文创作助手",
        &prompt,
    )
    .await?;

    Ok(Json(result))
}

async fn generate_layer2(
    State(state): State<AppState>,
    Json(req): Json<Layer2Request>,
) -> Result<Json<ChapterOutline>, StatusCode> {
    let characters_json = serde_json::to_string(&req.characters).unwrap_or_default();

    let mut ctx = tera::Context::new();
    ctx.insert("synopsis", &req.synopsis);
    ctx.insert("characters", &characters_json);
    ctx.insert("chapter_count", &req.chapter_count.unwrap_or(10).to_string());

    let prompt = state.templates.render("layer2", &ctx)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let result = call_llm_structured::<ChapterOutline>(
        &state.http_client,
        &state.ai_provider_url,
        "网文细纲创作助手",
        &prompt,
    )
    .await?;

    Ok(Json(result))
}

async fn stream_layer3(
    State(state): State<AppState>,
    Json(req): Json<StreamLayer3Request>,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, StatusCode> {
    let mut ctx = tera::Context::new();
    ctx.insert("synopsis", &req.synopsis);
    ctx.insert("character_context", &req.character_context);
    ctx.insert("chapter_context", &req.chapter_context);
    ctx.insert("scene_title", &req.scene.title);
    ctx.insert("scene_summary", &req.scene.summary);
    ctx.insert("scene_characters", &req.scene.characters.join("、"));
    ctx.insert("scene_location", &req.scene.location);
    ctx.insert("mood", &req.scene.mood);
    ctx.insert("conflict", &req.scene.conflict);

    let prompt = state.templates.render("layer3", &ctx)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let stream = stream_from_provider(
        &state.http_client,
        &state.ai_provider_url,
        "网文正文创作助手",
        &prompt,
    )
    .await
    .map_err(|_| StatusCode::BAD_GATEWAY)?;

    Ok(stream)
}

async fn continue_writing(
    State(state): State<AppState>,
    Json(req): Json<ContinueRequest>,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, StatusCode> {
    let prompt = format!(
        "请继续以下小说正文的写作，保持风格和情节连贯：\n\n{}\n\n---\n\n继续写：",
        req.text
    );

    let stream = stream_from_provider(
        &state.http_client,
        &state.ai_provider_url,
        "网文续写助手",
        &prompt,
    )
    .await
    .map_err(|_| StatusCode::BAD_GATEWAY)?;

    Ok(stream)
}

// ---- LLM 调用 ----

async fn call_llm_structured<T: for<'de> Deserialize<'de>>(
    client: &reqwest::Client,
    provider_url: &str,
    system: &str,
    prompt: &str,
) -> Result<T, StatusCode> {
    let payload = serde_json::json!({
        "provider": "openai",
        "model": "gpt-4o",
        "system_prompt": system,
        "user_prompt": prompt,
        "temperature": 0.3,
        "max_tokens": 4096,
    });

    let resp = client
        .post(format!("{}/api/v1/ai/structured", provider_url))
        .json(&payload)
        .send()
        .await
        .map_err(|e| {
            tracing::error!("AI Provider call failed: {}", e);
            StatusCode::BAD_GATEWAY
        })?;

    let body: serde_json::Value = resp.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let json_str = body["json"]
        .as_str()
        .ok_or_else(|| {
            tracing::error!("No json in response: {:?}", body);
            StatusCode::BAD_GATEWAY
        })?;

    serde_json::from_str(json_str).map_err(|e| {
        tracing::error!("Parse failed: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })
}

async fn stream_from_provider(
    client: &reqwest::Client,
    provider_url: &str,
    system: &str,
    prompt: &str,
) -> Result<Sse<impl Stream<Item = Result<Event, Infallible>>>, StatusCode> {
    let payload = serde_json::json!({
        "provider": "openai",
        "model": "gpt-4o",
        "system_prompt": system,
        "user_prompt": prompt,
        "temperature": 0.8,
        "max_tokens": 4096,
    });

    let stream = async_stream::stream! {
        let resp = match client
            .post(format!("{}/api/v1/ai/stream", provider_url))
            .json(&payload)
            .send()
            .await
        {
            Ok(r) => r,
            Err(e) => {
                yield Ok(Event::default().data(format!("error: {}", e)));
                return;
            }
        };

        let mut buf = String::new();
        use futures::StreamExt;
        let mut byte_stream = resp.bytes_stream();

        while let Some(chunk) = byte_stream.next().await {
            match chunk {
                Ok(bytes) => {
                    let text = String::from_utf8_lossy(&bytes);
                    yield Ok(Event::default().data(text.to_string()));
                }
                Err(e) => {
                    yield Ok(Event::default().data(format!("error: {}", e)));
                }
            }
        }

        yield Ok(Event::default().data("[DONE]"));
    };

    Ok(Sse::new(stream).keep_alive(axum::response::sse::KeepAlive::new()))
}