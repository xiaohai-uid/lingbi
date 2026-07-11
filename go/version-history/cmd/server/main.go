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
	"github.com/jackc/pgx/v5/pgxpool"
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/version-history/internal/handler"
	"github.com/xiaohai-uid/lingbi/version-history/internal/repository"
)

func main() {
	port := getEnv("PORT", "8086")
	dbURL := getEnv("DB_URL", "postgres://lingbi:lingbi_dev@postgres:5432/lingbi?sslmode=disable")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		logger.Fatal("db connection failed", zap.Error(err))
	}
	defer pool.Close()

	repo := repository.NewVersionRepo(pool)
	h := handler.NewVersionHandler(repo)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), cors.Default())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "version-history"})
	})

	v1 := r.Group("/api/v1/versions/:docId")
	{
		v1.POST("/snapshot", h.Snapshot)
		v1.GET("/history", h.GetHistory)
		v1.GET("/snapshot/:version", h.GetSnapshot)
		v1.GET("/diff", h.Diff)
	}

	srv := &http.Server{Addr: fmt.Sprintf(":%s", port), Handler: r}
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()
	logger.Info("Version History Service started", zap.String("port", port))

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