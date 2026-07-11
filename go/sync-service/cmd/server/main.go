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
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/sync-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/sync-service/internal/repository"
)

func main() {
	port := getEnv("PORT", "8090")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	repo := repository.NewSyncRepo()
	h := handler.NewSyncHandler(repo)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), cors.Default())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "sync-service"})
	})

	v1 := r.Group("/api/v1/sync")
	{
		v1.GET("/status", h.GetStatus)
		v1.GET("/config", h.GetConfig)
		v1.PUT("/config", h.SetConfig)
		v1.POST("/trigger", h.TriggerSync)
	}

	srv := &http.Server{Addr: fmt.Sprintf(":%s", port), Handler: r}
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()
	logger.Info("Sync Service started", zap.String("port", port))

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