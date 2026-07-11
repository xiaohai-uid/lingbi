package repository

import (
	"context"
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xiaohai-uid/lingbi/document-service/internal/model"
)

type DocumentRepo struct {
	pool *pgxpool.Pool
}

func NewDocumentRepo(pool *pgxpool.Pool) *DocumentRepo {
	return &DocumentRepo{pool: pool}
}

func countWords(content string) int {
	words := strings.Fields(content)
	// Try Chinese character counting too
	total := len(words)
	for _, w := range words {
		if utf8.RuneCountInString(w) > 2 {
			// This is likely Chinese — count characters instead
			total += utf8.RuneCountInString(w) - 1
		}
	}
	return total
}

func (r *DocumentRepo) Get(ctx context.Context, id string) (*model.Document, error) {
	d := &model.Document{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, scene_id, content, word_count, created_at, updated_at
		 FROM documents WHERE id=$1`, id,
	).Scan(&d.ID, &d.SceneID, &d.Content, &d.WordCount, &d.CreatedAt, &d.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("document not found: %w", err)
	}
	return d, nil
}

func (r *DocumentRepo) Save(ctx context.Context, d *model.Document) error {
	d.WordCount = countWords(d.Content)
	_, err := r.pool.Exec(ctx,
		`INSERT INTO documents (id, scene_id, content, word_count, updated_at)
		 VALUES ($1,$2,$3,$4,NOW())
		 ON CONFLICT (scene_id) DO UPDATE SET content=$3, word_count=$4, updated_at=NOW()`,
		d.ID, d.SceneID, d.Content, d.WordCount)
	return err
}

func (r *DocumentRepo) Search(ctx context.Context, query string, limit int) ([]model.Document, error) {
	if limit <= 0 {
		limit = 10
	}
	rows, err := r.pool.Query(ctx,
		`SELECT id, scene_id, content, word_count, created_at, updated_at
		 FROM documents
		 WHERE to_tsvector('simple', content) @@ plainto_tsquery('simple', $1)
		 ORDER BY updated_at DESC LIMIT $2`, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var docs []model.Document
	for rows.Next() {
		var d model.Document
		if err := rows.Scan(&d.ID, &d.SceneID, &d.Content, &d.WordCount, &d.CreatedAt, &d.UpdatedAt); err != nil {
			return nil, err
		}
		docs = append(docs, d)
	}
	return docs, nil
}

func (r *DocumentRepo) GetWordCount(ctx context.Context, docID string) (int, error) {
	var count int
	err := r.pool.QueryRow(ctx, `SELECT word_count FROM documents WHERE id=$1`, docID).Scan(&count)
	return count, err
}