package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/xiaohai-uid/lingbi/project-service/internal/model"
)

type ProjectRepo struct {
	pool *pgxpool.Pool
}

func NewProjectRepo(pool *pgxpool.Pool) *ProjectRepo {
	return &ProjectRepo{pool: pool}
}

// ---- World ----

func (r *ProjectRepo) CreateWorld(ctx context.Context, w *model.World) error {
	return r.pool.QueryRow(ctx,
		`INSERT INTO worlds (name, description, genres) VALUES ($1, $2, $3)
		 RETURNING id, created_at, updated_at`,
		w.Name, w.Description, w.Genres,
	).Scan(&w.ID, &w.CreatedAt, &w.UpdatedAt)
}

func (r *ProjectRepo) GetWorld(ctx context.Context, id string) (*model.World, error) {
	w := &model.World{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, name, description, genres, created_at, updated_at FROM worlds WHERE id = $1`, id,
	).Scan(&w.ID, &w.Name, &w.Description, &w.Genres, &w.CreatedAt, &w.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("world not found: %w", err)
	}
	return w, nil
}

func (r *ProjectRepo) ListWorlds(ctx context.Context) ([]model.World, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, name, description, genres, created_at, updated_at FROM worlds ORDER BY updated_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var worlds []model.World
	for rows.Next() {
		var w model.World
		if err := rows.Scan(&w.ID, &w.Name, &w.Description, &w.Genres, &w.CreatedAt, &w.UpdatedAt); err != nil {
			return nil, err
		}
		worlds = append(worlds, w)
	}
	return worlds, nil
}

func (r *ProjectRepo) UpdateWorld(ctx context.Context, w *model.World) error {
	_, err := r.pool.Exec(ctx,
		`UPDATE worlds SET name=$1, description=$2, genres=$3 WHERE id=$4`,
		w.Name, w.Description, w.Genres, w.ID)
	return err
}

func (r *ProjectRepo) DeleteWorld(ctx context.Context, id string) error {
	_, err := r.pool.Exec(ctx, `DELETE FROM worlds WHERE id = $1`, id)
	return err
}

// ---- Work ----

func (r *ProjectRepo) CreateWork(ctx context.Context, w *model.Work) error {
	return r.pool.QueryRow(ctx,
		`INSERT INTO works (world_id, title, description) VALUES ($1, $2, $3)
		 RETURNING id, created_at, updated_at`,
		w.WorldID, w.Title, w.Description,
	).Scan(&w.ID, &w.CreatedAt, &w.UpdatedAt)
}

func (r *ProjectRepo) GetWork(ctx context.Context, id string) (*model.Work, error) {
	w := &model.Work{}
	err := r.pool.QueryRow(ctx,
		`SELECT id, world_id, title, description, volume_count, created_at, updated_at FROM works WHERE id = $1`, id,
	).Scan(&w.ID, &w.WorldID, &w.Title, &w.Description, &w.VolumeCount, &w.CreatedAt, &w.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("work not found: %w", err)
	}
	return w, nil
}

func (r *ProjectRepo) ListWorks(ctx context.Context, worldID string) ([]model.Work, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, world_id, title, description, volume_count, created_at, updated_at FROM works WHERE world_id = $1 ORDER BY created_at`, worldID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var works []model.Work
	for rows.Next() {
		var w model.Work
		if err := rows.Scan(&w.ID, &w.WorldID, &w.Title, &w.Description, &w.VolumeCount, &w.CreatedAt, &w.UpdatedAt); err != nil {
			return nil, err
		}
		works = append(works, w)
	}
	return works, nil
}

// ---- Volume ----

func (r *ProjectRepo) CreateVolume(ctx context.Context, v *model.Volume) error {
	return r.pool.QueryRow(ctx,
		`INSERT INTO volumes (work_id, title, summary, sort_order) VALUES ($1, $2, $3, $4)
		 RETURNING id`,
		v.WorkID, v.Title, v.Summary, v.SortOrder,
	).Scan(&v.ID)
}

func (r *ProjectRepo) ListVolumes(ctx context.Context, workID string) ([]model.Volume, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, work_id, title, summary, chapter_count, sort_order FROM volumes WHERE work_id = $1 ORDER BY sort_order`, workID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var vols []model.Volume
	for rows.Next() {
		var v model.Volume
		if err := rows.Scan(&v.ID, &v.WorkID, &v.Title, &v.Summary, &v.ChapterCount, &v.SortOrder); err != nil {
			return nil, err
		}
		vols = append(vols, v)
	}
	return vols, nil
}

// ---- Chapter ----

func (r *ProjectRepo) CreateChapter(ctx context.Context, c *model.Chapter) error {
	return r.pool.QueryRow(ctx,
		`INSERT INTO chapters (volume_id, title, summary, sort_order) VALUES ($1, $2, $3, $4)
		 RETURNING id`,
		c.VolumeID, c.Title, c.Summary, c.SortOrder,
	).Scan(&c.ID)
}

func (r *ProjectRepo) ListChapters(ctx context.Context, volumeID string) ([]model.Chapter, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, volume_id, title, summary, scene_count, sort_order FROM chapters WHERE volume_id = $1 ORDER BY sort_order`, volumeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var chs []model.Chapter
	for rows.Next() {
		var c model.Chapter
		if err := rows.Scan(&c.ID, &c.VolumeID, &c.Title, &c.Summary, &c.SceneCount, &c.SortOrder); err != nil {
			return nil, err
		}
		chs = append(chs, c)
	}
	return chs, nil
}

// ---- Scene ----

func (r *ProjectRepo) CreateScene(ctx context.Context, s *model.Scene) error {
	return r.pool.QueryRow(ctx,
		`INSERT INTO scenes (chapter_id, title, summary, sort_order) VALUES ($1, $2, $3, $4)
		 RETURNING id`,
		s.ChapterID, s.Title, s.Summary, s.SortOrder,
	).Scan(&s.ID)
}

func (r *ProjectRepo) ListScenes(ctx context.Context, chapterID string) ([]model.Scene, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, chapter_id, title, summary, document_id, sort_order FROM scenes WHERE chapter_id = $1 ORDER BY sort_order`, chapterID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var scenes []model.Scene
	for rows.Next() {
		var s model.Scene
		if err := rows.Scan(&s.ID, &s.ChapterID, &s.Title, &s.Summary, &s.DocumentID, &s.SortOrder); err != nil {
			return nil, err
		}
		scenes = append(scenes, s)
	}
	return scenes, nil
}

// ---- Tree ----

func (r *ProjectRepo) GetWorldTree(ctx context.Context, worldID string) (*model.WorldTree, error) {
	tree := &model.WorldTree{
		Volumes:  make(map[string][]model.Volume),
		Chapters: make(map[string][]model.Chapter),
		Scenes:   make(map[string][]model.Scene),
	}

	works, err := r.ListWorks(ctx, worldID)
	if err != nil {
		return nil, err
	}
	tree.Works = works

	for _, work := range works {
		vols, _ := r.ListVolumes(ctx, work.ID)
		tree.Volumes[work.ID] = vols
		for _, vol := range vols {
			chs, _ := r.ListChapters(ctx, vol.ID)
			tree.Chapters[vol.ID] = chs
			for _, ch := range chs {
				scenes, _ := r.ListScenes(ctx, ch.ID)
				tree.Scenes[ch.ID] = scenes
			}
		}
	}

	return tree, nil
}