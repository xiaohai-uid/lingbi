package model

import "time"

type TimelineEvent struct {
	ID                  string   `json:"id"`
	WorldID             string   `json:"world_id"`
	Title               string   `json:"title"`
	Description          string   `json:"description"`
	StoryTime           int64    `json:"story_time"`
	InvolvedCharacterIDs []string `json:"involved_character_ids"`
	CreatedAt           time.Time `json:"created_at"`
}