use sqlx::PgPool;
use uuid::Uuid;
use crate::models::Skill;

/// PostgreSQL 存储层
#[derive(Clone)]
pub struct SkillStorage {
    pool: PgPool,
}

impl SkillStorage {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn init_table(&self) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS skills (
                id UUID PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                version VARCHAR(50) NOT NULL DEFAULT '1.0.0',
                skill_type VARCHAR(50) NOT NULL DEFAULT 'writing',
                author VARCHAR(255) NOT NULL DEFAULT 'anonymous',
                description TEXT NOT NULL DEFAULT '',
                icon VARCHAR(50) NOT NULL DEFAULT '🔧',
                prompt_template TEXT NOT NULL,
                variables JSONB NOT NULL DEFAULT '{}',
                category VARCHAR(100) NOT NULL DEFAULT 'general',
                downloads INTEGER NOT NULL DEFAULT 0,
                rating REAL NOT NULL DEFAULT 0.0,
                source VARCHAR(50) NOT NULL DEFAULT 'local',
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
            "#,
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn list_skills(&self, page: i64, page_size: i64) -> Result<SkillListResponse, sqlx::Error> {
        let offset = (page - 1) * page_size;
        let skills = sqlx::query_as::<_, Skill>(
            "SELECT * FROM skills ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        )
        .bind(page_size)
        .bind(offset)
        .fetch_all(&self.pool)
        .await?;

        let total: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM skills")
            .fetch_one(&self.pool)
            .await?;

        Ok(SkillListResponse {
            skills,
            total: total.0 as i32,
        })
    }

    pub async fn get_skill(&self, id: &str) -> Result<Option<Skill>, sqlx::Error> {
        sqlx::query_as::<_, Skill>("SELECT * FROM skills WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
    }

    pub async fn create_skill(&self, skill: &Skill) -> Result<Skill, sqlx::Error> {
        sqlx::query_as::<_, Skill>(
            r#"
            INSERT INTO skills (id, name, version, skill_type, author, description, icon,
                                prompt_template, variables, category, downloads, rating, source,
                                created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
            RETURNING *
            "#,
        )
        .bind(&skill.id)
        .bind(&skill.name)
        .bind(&skill.version)
        .bind(&skill.skill_type)
        .bind(&skill.author)
        .bind(&skill.description)
        .bind(&skill.icon)
        .bind(&skill.prompt_template)
        .bind(&skill.variables)
        .bind(&skill.category)
        .bind(skill.downloads)
        .bind(skill.rating)
        .bind(&skill.source)
        .bind(skill.created_at)
        .bind(skill.updated_at)
        .fetch_one(&self.pool)
        .await
    }

    pub async fn update_skill(&self, id: &str, skill: &Skill) -> Result<Option<Skill>, sqlx::Error> {
        sqlx::query_as::<_, Skill>(
            r#"
            UPDATE skills SET name=$1, version=$2, skill_type=$3, author=$4, description=$5,
                              icon=$6, prompt_template=$7, variables=$8, category=$9,
                              downloads=$10, rating=$11, source=$12, updated_at=NOW()
            WHERE id=$13 RETURNING *
            "#,
        )
        .bind(&skill.name)
        .bind(&skill.version)
        .bind(&skill.skill_type)
        .bind(&skill.author)
        .bind(&skill.description)
        .bind(&skill.icon)
        .bind(&skill.prompt_template)
        .bind(&skill.variables)
        .bind(&skill.category)
        .bind(skill.downloads)
        .bind(skill.rating)
        .bind(&skill.source)
        .bind(id)
        .fetch_optional(&self.pool)
        .await
    }

    pub async fn delete_skill(&self, id: &str) -> Result<bool, sqlx::Error> {
        let result = sqlx::query("DELETE FROM skills WHERE id = $1")
            .bind(id)
            .execute(&self.pool)
            .await?;
        Ok(result.rows_affected() > 0)
    }
}

use crate::models::SkillListResponse;
