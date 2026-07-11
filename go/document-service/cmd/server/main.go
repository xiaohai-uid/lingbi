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

	"github.com/xiaohai-uid/lingbi/document-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/document-service/internal/repository"
)

func main() {
	port := getEnv("PORT", "8083")
	dbURL := getEnv("DB_URL", "postgres://lingbi:lingbi_dev@postgres:5432/lingbi?sslmode=disable")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		logger.Fatal("db connection failed", zap.Error(err))
	}
	defer pool.Close()

	repo := repository.NewDocumentRepo(pool)
	h := handler.NewDocumentHandler(repo)

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery(), cors.Default())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "document-service"})
	})

	v1 := r.Group("/api/v1/documents")
	{
		v1.GET("/:id", h.Get)
		v1.PUT("/:id", h.Save)
		v1.POST("", h.Save)
		v1.GET("/:id/word-count", h.GetWordCount)
		v1.GET("/search", h.Search)
	}

	srv := &http.Server{Addr: fmt.Sprintf(":%s", port), Handler: r}
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()
	logger.Info("Document Service started", zap.String("port", port))

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