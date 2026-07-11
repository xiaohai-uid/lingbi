package model

import "time"

type World struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Genres      []string `json:"genres"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Work struct {
	ID          string    `json:"id"`
	WorldID     string    `json:"world_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	VolumeCount int       `json:"volume_count"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type Volume struct {
	ID           string `json:"id"`
	WorkID       string `json:"work_id"`
	Title        string `json:"title"`
	Summary      string `json:"summary"`
	ChapterCount int    `json:"chapter_count"`
	SortOrder    int    `json:"sort_order"`
}

type Chapter struct {
	ID         string `json:"id"`
	VolumeID   string `json:"volume_id"`
	Title      string `json:"title"`
	Summary    string `json:"summary"`
	SceneCount int    `json:"scene_count"`
	SortOrder  int    `json:"sort_order"`
}

type Scene struct {
	ID         string `json:"id"`
	ChapterID  string `json:"chapter_id"`
	Title      string `json:"title"`
	Summary    string `json:"summary"`
	DocumentID string `json:"document_id,omitempty"`
	SortOrder  int    `json:"sort_order"`
}

type WorldTree struct {
	Works    []Work            `json:"works"`
	Volumes  map[string][]Volume  `json:"volumes"`
	Chapters map[string][]Chapter `json:"chapters"`
	Scenes   map[string][]Scene   `json:"scenes"`
}