package auth

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/redis/go-redis/v9"
)

type Handler struct {
	jwtSecret string
	rdb       *redis.Client
}

func NewHandler(jwtSecret string, rdb *redis.Client) *Handler {
	return &Handler{jwtSecret: jwtSecret, rdb: rdb}
}

type LoginRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Token     string `json:"token"`
	ExpiresAt int64  `json:"expires_at"`
}

func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	// TODO: validate against external auth or local config
	expiresAt := time.Now().Add(24 * time.Hour)
	claims := jwt.MapClaims{
		"user_id": req.UserID,
		"exp":     expiresAt.Unix(),
		"iat":     time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString([]byte(h.jwtSecret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "token generation failed"})
		return
	}

	// Store in Redis for quick revocation check
	h.rdb.Set(context.Background(), "token:"+req.UserID, tokenStr, 24*time.Hour)

	c.JSON(http.StatusOK, LoginResponse{
		Token:     tokenStr,
		ExpiresAt: expiresAt.Unix(),
	})
}

func (h *Handler) Logout(c *gin.Context) {
	userID := c.GetString("user_id")
	h.rdb.Del(context.Background(), "token:"+userID)
	c.JSON(http.StatusOK, gin.H{"status": "logged out"})
}

func (h *Handler) Validate(c *gin.Context) {
	userID := c.GetString("user_id")
	c.JSON(http.StatusOK, gin.H{"user_id": userID, "valid": true})
}

func RegisterRoutes(r *gin.Engine, h *Handler) {
	r.POST("/auth/login", h.Login)
	r.POST("/auth/logout", h.Logout)
	r.GET("/auth/validate", h.Validate)
}