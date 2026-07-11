package model

import "time"

type QuotaRequest struct {
	UserID string `json:"user_id" binding:"required"`
	Model  string `json:"model" binding:"required"`
	Tokens int    `json:"tokens,omitempty"`
}

type QuotaStatus struct {
	UserID    string `json:"user_id"`
	Model     string `json:"model"`
	TokensUsed int64 `json:"tokens_used"`
	DailyLimit int64 `json:"daily_limit"`
	ResetAt   int64 `json:"reset_at"`
	Remaining int64 `json:"remaining"`
}

const (
	DefaultDailyLimit int64 = 100000
	QuotaKeyPrefix          = "quota:"
)