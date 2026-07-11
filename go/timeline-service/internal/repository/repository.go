package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xiaohai-uid/lingbi/timeline-service/internal/model"
)

type TimelineRepo struct {
	pool *pgxpool.Pool
}

func NewTimelineRepo(pool *pgxpool.Pool) *TimelineRepo {
	return &TimelineRepo{pool: pool}
}

func (r *TimelineRepo) Create(ctx context.Context, e *model.TimelineEvent) error {
	e.ID = uuid.New().String()
	return r.pool.QueryRow(ctx,
		`INSERT INTO timeline_events (id, world_id, title, description, story_time, character_ids)
		 VALUES ($1,$2,$3,$4,$5,$6) RETURNING created_at`,
		e.ID, e.WorldID, e.Title, e.Description, e.StoryTime, e.InvolvedCharacterIDs,
	).Scan(&e.CreatedAt)
}

func (r *TimelineRepo) Get(ctx context.Context, id string) (*model.TimelineEvent, error) {
	e := &model.TimelineEvent{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, world_id, title, description, story_time, character_ids, created_at
		 FROM timeline_events WHERE id=$1`, id,
	).Scan(&e.ID, &e.WorldID, &e.Title, &e.Description, &e.StoryTime, &e.InvolvedCharacterIDs, &e.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("event not found: %w", err)
	}
	return e, nil
}

func (r *TimelineRepo) List(ctx context.Context, worldID string) ([]model.TimelineEvent, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, world_id, title, description, story_time, character_ids, created_at
		 FROM timeline_events WHERE world_id=$1 ORDER BY story_time`, worldID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []model.TimelineEvent
	for rows.Next() {
		var e model.TimelineEvent
		if err := rows.Scan(&e.ID, &e.WorldID, &e.Title, &e.Description, &e.StoryTime, &e.InvolvedCharacterIDs, &e.CreatedAt); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	return events, nil
}

func (r *TimelineRepo) Update(ctx context.Context, e *model.TimelineEvent) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE timeline_events SET title=$1, description=$2, story_time=$3, character_ids=$4 WHERE id=$5`,
		e.Title, e.Description, e.StoryTime, e.InvolvedCharacterIDs, e.ID)
	return err
}

func (r *TimelineRepo) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM timeline_events WHERE id=$1`, id)
	return err
}