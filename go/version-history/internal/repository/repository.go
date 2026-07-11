package repository

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xiaohai-uid/lingbi/version-history/internal/model"
)

type VersionRepo struct {
	pool *pgxpool.Pool
}

func NewVersionRepo(pool *pgxpool.Pool) *VersionRepo {
	return &VersionRepo{pool: pool}
}

func (r *VersionRepo) Snapshot(ctx context.Context, docID, content string) (*model.VersionSnapshot, error) {
	var version int
	err := r.pool.QueryRow(ctx,
		`SELECT COALESCE(MAX(version), 0) + 1 FROM version_snapshots WHERE document_id=$1`, docID,
	).Scan(&version)
	if err != nil {
		version = 1
	}

	snap := &model.VersionSnapshot{
		DocumentID: docID,
		Content:    content,
		WordCount:  len(strings.Fields(content)),
		Version:    version,
	}

	err = r.pool.QueryRow(ctx,
		`INSERT INTO version_snapshots (document_id, content, word_count, version)
		 VALUES ($1,$2,$3,$4) RETURNING id, created_at`,
		snap.DocumentID, snap.Content, snap.WordCount, snap.Version,
	).Scan(&snap.ID, &snap.CreatedAt)

	return snap, err
}

func (r *VersionRepo) GetHistory(ctx context.Context, docID string) ([]model.VersionSnapshot, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, document_id, content, word_count, version, created_at
		 FROM version_snapshots WHERE document_id=$1 ORDER BY version DESC`, docID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var snaps []model.VersionSnapshot
	for rows.Next() {
		var s model.VersionSnapshot
		if err := rows.Scan(&s.ID, &s.DocumentID, &s.Content, &s.WordCount, &s.Version, &s.CreatedAt); err != nil {
			return nil, err
		}
		snaps = append(snaps, s)
	}
	return snaps, nil
}

func (r *VersionRepo) GetSnapshot(ctx context.Context, docID string, version int) (*model.VersionSnapshot, error) {
	s := &model.VersionSnapshot{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, document_id, content, word_count, version, created_at
		 FROM version_snapshots WHERE document_id=$1 AND version=$2`, docID, version,
	).Scan(&s.ID, &s.DocumentID, &s.Content, &s.WordCount, &s.Version, &s.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("snapshot not found: %w", err)
	}
	return s, nil
}

func (r *VersionRepo) Diff(ctx context.Context, docID string, v1, v2 int) (*model.DiffResult, error) {
	snap1, err := r.GetSnapshot(ctx, docID, v1)
	if err != nil {
		return nil, err
	}
	snap2, err := r.GetSnapshot(ctx, docID, v2)
	if err != nil {
		return nil, err
	}

	result := &model.DiffResult{
		OldVersion: v1,
		NewVersion: v2,
	}

	// Simple line-based diff
	lines1 := strings.Split(snap1.Content, "\n")
	lines2 := strings.Split(snap2.Content, "\n")

	set1 := make(map[string]bool)
	for _, l := range lines1 {
		set1[l] = true
	}
	for _, l := range lines2 {
		if !set1[l] {
			result.Added++
			result.Diff += fmt.Sprintf("+ %s\n", l)
		}
	}

	set2 := make(map[string]bool)
	for _, l := range lines2 {
		set2[l] = true
	}
	for _, l := range lines1 {
		if !set2[l] {
			result.Removed++
			result.Diff += fmt.Sprintf("- %s\n", l)
		}
	}

	return result, nil
}