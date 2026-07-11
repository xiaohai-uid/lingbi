package repository

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

const settingsPrefix = "settings:"

type SettingsRepo struct {
	rdb *redis.Client
}

func NewSettingsRepo(rdb *redis.Client) *SettingsRepo {
	return &SettingsRepo{rdb: rdb}
}

func (r *SettingsRepo) Get(ctx context.Context, key string) (string, error) {
	val, err := r.rdb.Get(ctx, settingsPrefix+key).Result()
	if err == redis.Nil {
		return "", fmt.Errorf("setting not found: %s", key)
	}
	return val, err
}

func (r *SettingsRepo) Set(ctx context.Context, key, value string) error {
	return r.rdb.Set(ctx, settingsPrefix+key, value, 0).Err()
}

func (r *SettingsRepo) GetAll(ctx context.Context) (map[string]string, error) {
	keys, err := r.rdb.Keys(ctx, settingsPrefix+"*").Result()
	if err != nil {
		return nil, err
	}
	if len(keys) == 0 {
		return map[string]string{}, nil
	}

	vals, err := r.rdb.MGet(ctx, keys...).Result()
	if err != nil {
		return nil, err
	}

	result := make(map[string]string, len(keys))
	for i, key := range keys {
		if vals[i] != nil {
			k := key[len(settingsPrefix):]
			result[k] = vals[i].(string)
		}
	}
	return result, nil
}

func (r *SettingsRepo) Reset(ctx context.Context) error {
	keys, err := r.rdb.Keys(ctx, settingsPrefix+"*").Result()
	if err != nil {
		return err
	}
	if len(keys) > 0 {
		return r.rdb.Del(ctx, keys...).Err()
	}
	return nil
}