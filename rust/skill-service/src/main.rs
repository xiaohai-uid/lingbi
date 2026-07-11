mod distiller;
mod executor;
mod handlers;
mod models;
mod storage;

use axum::serve;
use std::net::SocketAddr;
use tokio::net::TcpListener;
use tracing::info;

use crate::executor::SkillExecutor;
use crate::handlers::{routes, AppState};
use crate::storage::SkillStorage;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "skill=info".into()),
        )
        .init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "8097".to_string());
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://lingbi:lingbi@localhost:5432/lingbi".to_string());
    let ai_provider_url =
        std::env::var("AI_PROVIDER_URL").unwrap_or_else(|_| "http://localhost:8081".to_string());

    // PostgreSQL 连接池
    let pool = sqlx::postgres::PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("Failed to connect to PostgreSQL");

    let storage = SkillStorage::new(pool.clone());
    storage
        .init_table()
        .await
        .expect("Failed to initialize skills table");

    let executor = SkillExecutor::new(ai_provider_url);

    let app = routes(AppState { storage, executor });

    let addr: SocketAddr = format!("0.0.0.0:{}", port)
        .parse()
        .expect("Invalid port");
    info!("Skill Service starting on {}", addr);

    let listener = TcpListener::bind(addr).await.unwrap();
    serve(listener, app).await.unwrap();
}
