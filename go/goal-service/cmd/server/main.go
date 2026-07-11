package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/goal-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/goal-service/internal/storage"
)

func main() {
	port := getEnv("PORT", "8102")
	pgURL := getEnv("DATABASE_URL", "postgres://lingbi:lingbi@localhost:5432/lingbi")
	redisURL := getEnv("REDIS_URL", "localhost:6379")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	rdb := redis.NewClient(&redis.Options{Addr: redisURL})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		logger.Warn("redis not available", zap.Error(err))
	}

	store := storage.NewStorage(pgURL, rdb)
	if err := store.Init(); err != nil {
		logger.Fatal("db init failed", zap.Error(err))
	}

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(cors.New(cors.Config{
		AllowOrigins: []string{"*"}, AllowMethods: []string{"GET", "POST", "PUT"},
		AllowHeaders: []string{"Origin", "Content-Type"}, MaxAge: 12 * time.Hour,
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "lingbi-goal-service"})
	})

	h := handler.NewHandler(store)
	api := r.Group("/api/v1/goals")
	{
		api.POST("/record", h.RecordWriting)
		api.GET("/today", h.GetTodayStats)
		api.GET("/month", h.GetMonthStats)
		api.GET("/streak", h.GetStreak)
		api.POST("/set", h.SetGoal)
		api.GET("/progress", h.GetProgress)
	}

	srv := &http.Server{Addr: fmt.Sprintf(":%s", port), Handler: r,
		ReadTimeout: 30 * time.Second, WriteTimeout: 30 * time.Second}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()
	logger.Info("Goal Service started", zap.String("port", port))

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	srv.Shutdown(ctx)
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
