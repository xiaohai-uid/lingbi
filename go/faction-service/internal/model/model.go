package model

import "time"

type Faction struct {
	ID          string   `json:"id"`
	WorldID     string   `json:"world_id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	MemberIDs   []string `json:"member_ids"`
	LeaderID    string   `json:"leader_id,omitempty"`
	CreatedAt   time.Time `json:"created_at"`
}