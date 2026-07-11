package model

import "time"

type Document struct {
	ID        string    `json:"id"`
	SceneID   string    `json:"scene_id"`
	Content   string    `json:"content"`
	WordCount int       `json:"word_count"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}