package repository

import (
	"fmt"
	"sync"
	"time"

	"github.com/xiaohai-uid/lingbi/sync-service/internal/model"
)

type SyncRepo struct {
	mu       sync.RWMutex
	config   model.SyncConfig
	lastSync int64
	running  bool
}

func NewSyncRepo() *SyncRepo {
	return &SyncRepo{
		config: model.SyncConfig{
			Enabled:  false,
			Interval: 30,
		},
	}
}

func (r *SyncRepo) GetConfig() model.SyncConfig {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.config
}

func (r *SyncRepo) SetConfig(cfg model.SyncConfig) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.config = cfg
	return nil
}

func (r *SyncRepo) TriggerSync() (*model.SyncStatus, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.running {
		return nil, fmt.Errorf("sync already in progress")
	}

	r.running = true
	r.lastSync = time.Now().Unix()

	// Simulated sync — in production, this would call WebDAV
	time.Sleep(500 * time.Millisecond)

	r.running = false
	return &model.SyncStatus{
		Status:    "completed",
		LastSync:  r.lastSync,
		FileCount: 0,
	}, nil
}

func (r *SyncRepo) GetStatus() *model.SyncStatus {
	r.mu.RLock()
	defer r.mu.RUnlock()

	status := "idle"
	if r.running {
		status = "syncing"
	}

	return &model.SyncStatus{
		Status:    status,
		LastSync:  r.lastSync,
		FileCount: 0,
	}
}