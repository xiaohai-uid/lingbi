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

	"github.com/xiaohai-uid/lingbi/api-gateway/internal/auth"
	"github.com/xiaohai-uid/lingbi/api-gateway/internal/middleware"
	"github.com/xiaohai-uid/lingbi/api-gateway/internal/router"
)

func main() {
	port := getEnv("PORT", "8080")
	redisURL := getEnv("REDIS_URL", "localhost:6379")
	jwtSecret := getEnv("JWT_SECRET", "dev-secret")

	// Logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	// Redis
	rdb := redis.NewClient(&redis.Options{
		Addr: redisURL,
	})
	if err := rdb.Ping(context.Background()).Err(); err != nil {
		logger.Fatal("redis connection failed", zap.Error(err))
	}

	// Gin
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))
	r.Use(middleware.Logger(logger))
	r.Use(middleware.RateLimiter(rdb))

	// Health
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "lingbi-api-gateway",
			"version": "4.0.0",
		})
	})

	// Auth routes
	authHandler := auth.NewHandler(jwtSecret, rdb)
	auth.RegisterRoutes(r, authHandler)

	// Protected API routes
	api := r.Group("/api/v1")
	api.Use(middleware.JWTAuth(jwtSecret))
	{
		router.RegisterProjectRoutes(api, "http://project-service:8082")
		router.RegisterDocumentRoutes(api, "http://document-service:8083")
		router.RegisterAIServiceRoutes(api, "http://ai-provider:8081")
		router.RegisterNovelEngineRoutes(api, "http://novel-engine:8092")
		router.RegisterCanonRoutes(api, "http://canon-service:8084")
		router.RegisterQualityRoutes(api, "http://quality-review:8093")
		router.RegisterSettingsRoutes(api, "http://settings-service:8087")
		router.RegisterExportRoutes(api, "http://export-service:8085")
		router.RegisterTimelineRoutes(api, "http://timeline-service:8094")
		router.RegisterFactionRoutes(api, "http://faction-service:8095")
		router.RegisterSkillRoutes(api, "http://skill-service:8097")
		router.RegisterSearchRoutes(api, "http://search-service:8098")
		router.RegisterModelRoutes(api, "http://model-discovery:8099")
		router.RegisterMemoryRoutes(api, "http://memory-service:8100")
		router.RegisterStyleRoutes(api, "http://style-service:8101")
		router.RegisterGoalRoutes(api, "http://goal-service:8102")
	}

	// Server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      r,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("server error", zap.Error(err))
		}
	}()

	logger.Info("API Gateway started", zap.String("port", port))

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