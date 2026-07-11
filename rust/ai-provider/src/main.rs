use axum::{
    extract::State,
    http::StatusCode,
    response::{sse::Event, Json, Sse},
    routing::{get, post},
    Router,
};
use futures::stream::Stream;
use serde::{Deserialize, Serialize};
use std::{convert::Infallible, sync::Arc};
use tokio::sync::Mutex;
use tracing::{info, error};

#[derive(Clone)]
struct AppState {
    http_client: reqwest::Client,
    litellm_url: String,
}

#[derive(Deserialize)]
struct GenerateRequest {
    provider: String,
    model: String,
    system_prompt: Option<String>,
    user_prompt: String,
    temperature: Option<f32>,
    max_tokens: Option<u32>,
}

#[derive(Serialize)]
struct GenerateResponse {
    text: String,
    prompt_tokens: u32,
    completion_tokens: u32,
    latency_ms: u64,
}

#[derive(Deserialize)]
struct StreamRequest {
    provider: String,
    model: String,
    system_prompt: Option<String>,
    user_prompt: String,
    temperature: Option<f32>,
    max_tokens: Option<u32>,
}

#[derive(Serialize)]
struct ModelInfo {
    name: String,
    provider: String,
    supports_stream: bool,
    supports_structured: bool,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter("ai_provider=info,tower_http=info")
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8081".to_string());
    let litellm_url = std::env::var("LITELLM_URL").unwrap_or_else(|_| "http://litellm:4000".to_string());

    let state = AppState {
        http_client: reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(120))
            .build()
            .expect("failed to create HTTP client"),
        litellm_url,
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/api/v1/ai/generate", post(generate_text))
        .route("/api/v1/ai/stream", post(stream_text))
        .route("/api/v1/ai/structured", post(generate_structured))
        .route("/api/v1/ai/models", get(list_models))
        .route("/api/v1/ai/embed", post(embed))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", port);
    info!("AI Provider starting on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .expect("failed to bind");

    axum::serve(listener, app)
        .await
        .expect("server error");
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "service": "ai-provider"
    }))
}

async fn generate_text(
    State(state): State<AppState>,
    Json(req): Json<GenerateRequest>,
) -> Result<Json<GenerateResponse>, StatusCode> {
    let start = std::time::Instant::now();

    let messages = build_messages(&req.system_prompt, &req.user_prompt);
    let payload = serde_json::json!({
        "model": format!("{}/{}", req.provider, req.model),
        "messages": messages,
        "temperature": req.temperature.unwrap_or(0.7),
        "max_tokens": req.max_tokens.unwrap_or(4096),
        "stream": false,
    });

    let resp = state.http_client
        .post(format!("{}/chat/completions", state.litellm_url))
        .json(&payload)
        .send()
        .await
        .map_err(|e| {
            error!("LLM request failed: {}", e);
            StatusCode::BAD_GATEWAY
        })?;

    let body: serde_json::Value = resp.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    let text = body["choices"][0]["message"]["content"]
        .as_str()
        .unwrap_or("")
        .to_string();
    let prompt_tokens = body["usage"]["prompt_tokens"].as_u64().unwrap_or(0) as u32;
    let completion_tokens = body["usage"]["completion_tokens"].as_u64().unwrap_or(0) as u32;

    let latency = start.elapsed().as_millis() as u64;
    info!("GenerateText: {} tokens in {}ms", completion_tokens, latency);

    Ok(Json(GenerateResponse {
        text,
        prompt_tokens,
        completion_tokens,
        latency_ms: latency,
    }))
}

async fn stream_text(
    State(state): State<AppState>,
    Json(req): Json<StreamRequest>,
) -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let messages = build_messages(&req.system_prompt, &req.user_prompt);
    let payload = serde_json::json!({
        "model": format!("{}/{}", req.provider, req.model),
        "messages": messages,
        "temperature": req.temperature.unwrap_or(0.7),
        "max_tokens": req.max_tokens.unwrap_or(4096),
        "stream": true,
    });

    let client = state.http_client.clone();
    let litellm_url = state.litellm_url.clone();

    let stream = async_stream::stream! {
        let resp = match client
            .post(format!("{}/chat/completions", litellm_url))
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
        let mut stream = resp.bytes_stream();

        use futures::StreamExt;
        while let Some(chunk) = stream.next().await {
            match chunk {
                Ok(bytes) => {
                    let text = String::from_utf8_lossy(&bytes);
                    buf.push_str(&text);
                    for line in buf.lines() {
                        if let Some(data) = line.strip_prefix("data: ") {
                            if data == "[DONE]" {
                                yield Ok(Event::default().data("[DONE]"));
                                return;
                            }
                            // Parse SSE chunk
                            if let Ok(val) = serde_json::from_str::<serde_json::Value>(data) {
                                if let Some(content) = val["choices"][0]["delta"]["content"].as_str() {
                                    yield Ok(Event::default().data(content.to_string()));
                                }
                            }
                        }
                    }
                    // Keep only the last incomplete line
                    if let Some(last_newline) = buf.rfind('\n') {
                        buf = buf[last_newline + 1..].to_string();
                    }
                }
                Err(e) => {
                    yield Ok(Event::default().data(format!("error: {}", e)));
                }
            }
        }
    };

    Sse::new(stream).keep_alive(axum::response::sse::KeepAlive::new())
}

async fn generate_structured(
    State(state): State<AppState>,
    Json(req): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let provider = req["provider"].as_str().unwrap_or("openai");
    let model = req["model"].as_str().unwrap_or("gpt-4o");
    let system_prompt = req["system_prompt"].as_str().unwrap_or("");
    let user_prompt = req["user_prompt"].as_str().unwrap_or("");
    let schema = req["schema_json"].as_str().unwrap_or("{}");

    let messages = build_messages(&Some(system_prompt.to_string()), user_prompt);
    let payload = serde_json::json!({
        "model": format!("{}/{}", provider, model),
        "messages": messages,
        "response_format": {
            "type": "json_object",
            "schema": serde_json::from_str::<serde_json::Value>(schema).ok()
        },
        "temperature": 0.3,
    });

    let resp = state.http_client
        .post(format!("{}/chat/completions", state.litellm_url))
        .json(&payload)
        .send()
        .await
        .map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: serde_json::Value = resp.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    Ok(Json(body))
}

async fn list_models() -> Json<Vec<ModelInfo>> {
    Json(vec![
        ModelInfo { name: "gpt-4o".into(), provider: "openai".into(), supports_stream: true, supports_structured: true },
        ModelInfo { name: "gpt-4o-mini".into(), provider: "openai".into(), supports_stream: true, supports_structured: true },
        ModelInfo { name: "claude-sonnet-4-20250514".into(), provider: "anthropic".into(), supports_stream: true, supports_structured: true },
        ModelInfo { name: "deepseek-chat".into(), provider: "deepseek".into(), supports_stream: true, supports_structured: true },
        ModelInfo { name: "qwen3.5-9b".into(), provider: "ollama".into(), supports_stream: true, supports_structured: false },
        ModelInfo { name: "yi-lightning".into(), provider: "01-ai".into(), supports_stream: true, supports_structured: false },
    ])
}

async fn embed(
    State(state): State<AppState>,
    Json(req): Json<serde_json::Value>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let texts = req["texts"].as_array().unwrap_or(&vec![]);
    let payload = serde_json::json!({
        "model": "openai/text-embedding-3-small",
        "input": texts,
    });

    let resp = state.http_client
        .post(format!("{}/embeddings", state.litellm_url))
        .json(&payload)
        .send()
        .await
        .map_err(|_| StatusCode::BAD_GATEWAY)?;

    let body: serde_json::Value = resp.json().await.map_err(|_| StatusCode::BAD_GATEWAY)?;
    Ok(Json(body))
}

fn build_messages(system_prompt: &Option<String>, user_prompt: &str) -> Vec<serde_json::Value> {
    let mut messages = Vec::new();
    if let Some(system) = system_prompt {
        if !system.is_empty() {
            messages.push(serde_json::json!({
                "role": "system",
                "content": system
            }));
        }
    }
    messages.push(serde_json::json!({
        "role": "user",
        "content": user_prompt
    }));
    messages
}