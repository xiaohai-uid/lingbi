package storage

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

type DailyStat struct {
	Date        string `json:"date"`
	WordCount   int    `json:"word_count"`
	SessionCnt  int    `json:"session_count"`
	MinutesUsed int    `json:"minutes_spent"`
}

type Goal struct {
	ID             string    `json:"id"`
	Type           string    `json:"type"`
	TargetWords    int       `json:"target_word_count"`
	IsActive       bool      `json:"is_active"`
}

type Storage struct {
	db  *sql.DB
	rdb *redis.Client
}

func NewStorage(pgURL string, rdb *redis.Client) *Storage {
	db, err := sql.Open("postgres", pgURL)
	if err != nil {
		panic(fmt.Sprintf("db open failed: %v", err))
	}
	return &Storage{db: db, rdb: rdb}
}

func (s *Storage) Init() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS daily_stats (
			id TEXT PRIMARY KEY, world_id TEXT NOT NULL, date TEXT NOT NULL,
			word_count INTEGER DEFAULT 0, session_count INTEGER DEFAULT 0,
			ai_call_count INTEGER DEFAULT 0, minutes_spent INTEGER DEFAULT 0,
			created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
		)`,
		`CREATE TABLE IF NOT EXISTS writing_goals (
			id TEXT PRIMARY KEY, world_id TEXT NOT NULL, type TEXT NOT NULL,
			target_word_count INTEGER NOT NULL, start_date TIMESTAMPTZ NOT NULL,
			end_date TIMESTAMPTZ, is_active BOOLEAN DEFAULT true,
			created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
		)`,
		`CREATE INDEX IF NOT EXISTS idx_daily_stats_world_date ON daily_stats(world_id, date)`,
	}
	for _, q := range queries {
		if _, err := s.db.Exec(q); err != nil {
			return fmt.Errorf("init query failed: %w", err)
		}
	}
	return nil
}

func (s *Storage) RecordWriting(worldID, date string, wordCount, minutes, aiCalls int) error {
	id := fmt.Sprintf("%s-%s", date, worldID)
	_, err := s.db.Exec(`
		INSERT INTO daily_stats (id, world_id, date, word_count, session_count, ai_call_count, minutes_spent, created_at, updated_at)
		VALUES ($1, $2, $3, $4, 1, $5, $6, NOW(), NOW())
		ON CONFLICT (id) DO UPDATE SET
			word_count = daily_stats.word_count + $4,
			session_count = daily_stats.session_count + 1,
			ai_call_count = daily_stats.ai_call_count + $5,
			minutes_spent = daily_stats.minutes_spent + $6,
			updated_at = NOW()
	`, id, worldID, date, wordCount, aiCalls, minutes)
	return err
}

func (s *Storage) GetTodayStats(worldID, date string) (*DailyStat, error) {
	row := s.db.QueryRow(
		`SELECT date, word_count, session_count, minutes_spent FROM daily_stats WHERE world_id=$1 AND date=$2`,
		worldID, date)
	var stat DailyStat
	err := row.Scan(&stat.Date, &stat.WordCount, &stat.SessionCnt, &stat.MinutesUsed)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &stat, err
}

func (s *Storage) GetMonthStats(worldID, yearMonth string) ([]DailyStat, error) {
	prefix := yearMonth + "%"
	rows, err := s.db.Query(
		`SELECT date, word_count, session_count, minutes_spent FROM daily_stats
		 WHERE world_id=$1 AND date LIKE $2 ORDER BY date DESC`, worldID, prefix)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var stats []DailyStat
	for rows.Next() {
		var stat DailyStat
		if err := rows.Scan(&stat.Date, &stat.WordCount, &stat.SessionCnt, &stat.MinutesUsed); err != nil {
			return nil, err
		}
		stats = append(stats, stat)
	}
	return stats, nil
}

func (s *Storage) GetStreak(worldID string) (int, error) {
	rows, err := s.db.Query(
		`SELECT date FROM daily_stats WHERE world_id=$1 ORDER BY date DESC`, worldID)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	var dates []string
	for rows.Next() {
		var d string
		rows.Scan(&d)
		dates = append(dates, d)
	}

	if len(dates) == 0 {
		return 0, nil
	}

	streak := 1
	for i := 0; i < len(dates)-1; i++ {
		curr, _ := time.Parse("2006-01-02", dates[i])
		next, _ := time.Parse("2006-01-02", dates[i+1])
		if curr.Sub(next).Hours() == 24 {
			streak++
		} else {
			break
		}
	}
	return streak, nil
}

func (s *Storage) SetGoal(worldID, goalType string, targetWords int) error {
	// Deactivate existing
	s.db.Exec(`UPDATE writing_goals SET is_active=false WHERE world_id=$1`, worldID)
	// Insert new
	id := fmt.Sprintf("%s-%s-%d", worldID, goalType, time.Now().Unix())
	_, err := s.db.Exec(
		`INSERT INTO writing_goals (id, world_id, type, target_word_count, start_date, is_active)
		 VALUES ($1,$2,$3,$4,NOW(),true)`, id, worldID, goalType, targetWords)
	return err
}

func (s *Storage) GetActiveGoal(worldID string) (*Goal, error) {
	row := s.db.QueryRow(
		`SELECT id, type, target_word_count, is_active FROM writing_goals
		 WHERE world_id=$1 AND is_active=true LIMIT 1`, worldID)
	var g Goal
	err := row.Scan(&g.ID, &g.Type, &g.TargetWords, &g.IsActive)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &g, err
}
