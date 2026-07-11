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

	"github.com/xiaohai-uid/lingbi/quota-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/quota-service/internal/repository"
)

func main() {
	port := getEnv("PORT", "8088")
	redisURL := getEnv("REDIS_URL", "redis:6379")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	rdb := redis.NewClient(&redis.Options{Addr: redisURL})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		logger.Fatal("redis connection failed", zap.Error(err))
	}

	repo := repository.NewQuotaRepo(rdb)
	h := handler.NewQuotaHandler(repo)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), cors.Default())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "quota-service"})
	})

	v1 := r.Group("/api/v1/quota")
	{
		v1.POST("/check", h.Check)
		v1.POST("/consume", h.Consume)
		v1.GET("/status/:userId", h.GetStatus)
		v1.POST("/reset", h.Reset)
	}

	srv := &http.Server{Addr: fmt.Sprintf(":%s", port), Handler: r}
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	logger.Info("Quota Service started", zap.String("port", port))
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