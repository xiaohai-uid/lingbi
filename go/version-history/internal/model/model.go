package model

import "time"

type VersionSnapshot struct {
	ID         string    `json:"id"`
	DocumentID string    `json:"document_id"`
	Content    string    `json:"content"`
	WordCount  int       `json:"word_count"`
	Version    int       `json:"version"`
	CreatedAt  time.Time `json:"created_at"`
}

type DiffResult struct {
	OldVersion int    `json:"old_version"`
	NewVersion int    `json:"new_version"`
	Diff       string `json:"diff"`
	Added      int    `json:"added"`
	Removed    int    `json:"removed"`
}