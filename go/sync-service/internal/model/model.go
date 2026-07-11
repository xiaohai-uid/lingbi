package model

type SyncStatus struct {
	Status    string `json:"status"`
	LastSync  int64  `json:"last_sync"`
	FileCount int    `json:"file_count"`
	Error     string `json:"error,omitempty"`
}

type SyncConfig struct {
	Enabled    bool   `json:"enabled"`
	ServerURL  string `json:"server_url"`
	Username   string `json:"username"`
	Password   string `json:"password,omitempty"`
	Interval   int    `json:"interval"` // minutes
}