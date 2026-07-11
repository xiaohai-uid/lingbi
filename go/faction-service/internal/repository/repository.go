package repository

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xiaohai-uid/lingbi/faction-service/internal/model"
)

type FactionRepo struct {
	pool *pgxpool.Pool
}

func NewFactionRepo(pool *pgxpool.Pool) *FactionRepo {
	return &FactionRepo{pool: pool}
}

func (r *FactionRepo) Create(ctx context.Context, f *model.Faction) error {
	f.ID = uuid.New().String()
	return r.pool.QueryRow(ctx,
		`INSERT INTO factions (id, world_id, name, description, member_ids, leader_id)
		 VALUES ($1,$2,$3,$4,$5,$6) RETURNING created_at`,
		f.ID, f.WorldID, f.Name, f.Description, f.MemberIDs, f.LeaderID,
	).Scan(&f.CreatedAt)
}

func (r *FactionRepo) Get(ctx context.Context, id string) (*model.Faction, error) {
	f := &model.Faction{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, world_id, name, description, member_ids, leader_id, created_at
		 FROM factions WHERE id=$1`, id,
	).Scan(&f.ID, &f.WorldID, &f.Name, &f.Description, &f.MemberIDs, &f.LeaderID, &f.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("faction not found: %w", err)
	}
	return f, nil
}

func (r *FactionRepo) List(ctx context.Context, worldID string) ([]model.Faction, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, world_id, name, description, member_ids, leader_id, created_at
		 FROM factions WHERE world_id=$1 ORDER BY name`, worldID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var factions []model.Faction
	for rows.Next() {
		var f model.Faction
		if err := rows.Scan(&f.ID, &f.WorldID, &f.Name, &f.Description, &f.MemberIDs, &f.LeaderID, &f.CreatedAt); err != nil {
			return nil, err
		}
		factions = append(factions, f)
	}
	return factions, nil
}

func (r *FactionRepo) Update(ctx context.Context, f *model.Faction) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE factions SET name=$1, description=$2, member_ids=$3, leader_id=$4 WHERE id=$5`,
		f.Name, f.Description, f.MemberIDs, f.LeaderID, f.ID)
	return err
}

func (r *FactionRepo) Delete(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM factions WHERE id=$1`, id)
	return err
}

func (r *FactionRepo) AddMember(ctx context.Context, id, memberID string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE factions SET member_ids = array_append(member_ids, $1) WHERE id=$2 AND NOT ($1 = ANY(member_ids))`,
		memberID, id)
	return err
}

func (r *FactionRepo) RemoveMember(ctx context.Context, id, memberID string) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE factions SET member_ids = array_remove(member_ids, $1) WHERE id=$2`,
		memberID, id)
	return err
}