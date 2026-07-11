package repository

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/xiaohai-uid/lingbi/quota-service/internal/model"
)

type QuotaRepo struct {
	rdb *redis.Client
}

func NewQuotaRepo(rdb *redis.Client) *QuotaRepo {
	return &QuotaRepo{rdb: rdb}
}

func quotaKey(userID, model string) string {
	return fmt.Sprintf("quota:%s:%s", userID, model)
}

func (r *QuotaRepo) Check(ctx context.Context, userID, model string) (*model.QuotaStatus, error) {
	key := quotaKey(userID, model)
	vals, err := r.rdb.HMGet(ctx, key, "tokens_used", "reset_at").Result()
	if err != nil {
		return nil, err
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	resetAt := today.Add(24 * time.Hour).Unix()

	var tokensUsed int64
	if vals[0] != nil {
		tokensUsed, _ = strconv.ParseInt(vals[0].(string), 10, 64)
	}
	if vals[1] != nil {
		if storedReset, _ := strconv.ParseInt(vals[1].(string), 10, 64); storedReset > resetAt {
			resetAt = storedReset
		}
	}

	// If reset time passed, reset counter
	if now.Unix() >= resetAt {
		tokensUsed = 0
		resetAt = today.Add(24 * time.Hour).Unix()
		r.rdb.HSet(ctx, key, "tokens_used", "0", "reset_at", resetAt)
		r.rdb.Expire(ctx, key, 48*time.Hour)
	}

	remaining := model.DefaultDailyLimit - tokensUsed
	if remaining < 0 {
		remaining = 0
	}

	return &model.QuotaStatus{
		UserID:     userID,
		Model:      model,
		TokensUsed: tokensUsed,
		DailyLimit: model.DefaultDailyLimit,
		ResetAt:    resetAt,
		Remaining:  remaining,
	}, nil
}

func (r *QuotaRepo) Consume(ctx context.Context, userID, model string, tokens int) (*model.QuotaStatus, error) {
	key := quotaKey(userID, model)

	status, err := r.Check(ctx, userID, model)
	if err != nil {
		return nil, err
	}
	if status.Remaining < int64(tokens) {
		return status, fmt.Errorf("quota exceeded: %d remaining, %d requested", status.Remaining, tokens)
	}

	newUsed := status.TokensUsed + int64(tokens)
	r.rdb.HSet(ctx, key, "tokens_used", newUsed)
	status.TokensUsed = newUsed
	status.Remaining = model.DefaultDailyLimit - newUsed
	return status, nil
}

func (r *QuotaRepo) GetStatus(ctx context.Context, userID string) ([]*model.QuotaStatus, error) {
	keys, err := r.rdb.Keys(ctx, fmt.Sprintf("quota:%s:*", userID)).Result()
	if err != nil {
		return nil, err
	}

	var statuses []*model.QuotaStatus
	for _, key := range keys {
		parts := len(key) - len(fmt.Sprintf("quota:%s:", userID))
		modelName := key[len(key)-parts:]
		s, err := r.Check(ctx, userID, modelName)
		if err == nil {
			statuses = append(statuses, s)
		}
	}
	return statuses, nil
}

func (r *QuotaRepo) Reset(ctx context.Context, userID, model string) error {
	key := quotaKey(userID, model)
	return r.rdb.Del(ctx, key).Err()
}