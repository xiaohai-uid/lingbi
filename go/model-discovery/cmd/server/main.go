package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/model-discovery/internal/handler"
	"github.com/xiaohai-uid/lingbi/model-discovery/internal/models"
	"github.com/xiaohai-uid/lingbi/model-discovery/internal/checker"
)

func main() {
	port := getEnv("PORT", "8099")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	registry := models.NewRegistry()
	healthChecker := checker.NewChecker()

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST"},
		AllowHeaders:     []string{"Origin", "Content-Type"},
		MaxAge:           12 * time.Hour,
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "lingbi-model-discovery",
			"version": "1.0.0",
		})
	})

	h := handler.NewHandler(registry, healthChecker)
	api := r.Group("/api/v1/models")
	{
		api.GET("/free", h.ListFree)
		api.POST("/test", h.TestConnection)
		api.POST("/recommend", h.Recommend)
	}

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	logger.Info("Model Discovery Service started", zap.String("port", port))

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal("server shutdown:", err)
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
