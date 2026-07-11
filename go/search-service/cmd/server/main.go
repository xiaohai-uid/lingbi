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
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"github.com/xiaohai-uid/lingbi/search-service/internal/handler"
	"github.com/xiaohai-uid/lingbi/search-service/internal/search"
	"github.com/xiaohai-uid/lingbi/search-service/internal/extractor"
	"github.com/xiaohai-uid/lingbi/search-service/internal/summarizer"
)

func main() {
	port := getEnv("PORT", "8098")
	redisURL := getEnv("REDIS_URL", "localhost:6379")
	aiProviderURL := getEnv("AI_PROVIDER_URL", "http://localhost:8081")

	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Redis (search cache)
	rdb := redis.NewClient(&redis.Options{
		Addr: redisURL,
	})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		logger.Warn("redis not available, search cache disabled", zap.Error(err))
	}

	// Services
	searcher := search.NewSearcher(rdb)
	extract := extractor.NewExtractor()
	summary := summarizer.NewSummarizer(aiProviderURL)

	// Gin
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		MaxAge:           12 * time.Hour,
	}))

	// Health
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "lingbi-search-service",
			"version": "1.0.0",
		})
	})

	// Search API
	h := handler.NewHandler(searcher, extract, summary)
	api := r.Group("/api/v1/search")
	{
		api.POST("/web", h.WebSearch)
	}

	// Server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 120 * time.Second, // long timeout for web scraping
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	logger.Info("Search Service started", zap.String("port", port))

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
