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
	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/project-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/project-service/internal/repository"
)

func main() {
	port := getEnv("PORT", "8082")
	dbURL := getEnv("DB_URL", "postgres://lingbi:lingbi_dev@localhost:5432/lingbi?sslmode=disable")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// PostgreSQL
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		logger.Fatal("db connection failed", zap.Error(err))
	}
	defer pool.Close()

	if err := pool.Ping(context.Background()); err != nil {
		logger.Fatal("db ping failed", zap.Error(err))
	}

	// Repo & Handler
	repo := repository.NewProjectRepo(pool)
	h := handler.NewProjectHandler(repo)

	// Gin
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(cors.Default())

	// Health
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "project-service"})
	})

	// API v1
	v1 := r.Group("/api/v1")
	{
		// World
		v1.POST("/worlds", h.CreateWorld)
		v1.GET("/worlds", h.ListWorlds)
		v1.GET("/worlds/:id", h.GetWorld)
		v1.PUT("/worlds/:id", h.UpdateWorld)
		v1.DELETE("/worlds/:id", h.DeleteWorld)

		// Work
		v1.POST("/works", h.CreateWork)
		v1.GET("/works", h.ListWorks)
		v1.GET("/works/:id", h.GetWork)

		// Volume
		v1.POST("/volumes", h.CreateVolume)
		v1.GET("/volumes", h.ListVolumes)

		// Chapter
		v1.POST("/chapters", h.CreateChapter)
		v1.GET("/chapters", h.ListChapters)

		// Scene
		v1.POST("/scenes", h.CreateScene)
		v1.GET("/scenes", h.ListScenes)

		// Tree
		v1.GET("/tree/:world_id", h.GetWorldTree)
	}

	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 30 * time.Second,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	logger.Info("Project Service started", zap.String("port", port))

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