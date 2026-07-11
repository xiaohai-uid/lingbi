package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/quota-service/internal/model"
	"github.com/xiaohai-uid/lingbi/quota-service/internal/repository"
)

type QuotaHandler struct {
	repo *repository.QuotaRepo
}

func NewQuotaHandler(repo *repository.QuotaRepo) *QuotaHandler {
	return &QuotaHandler{repo: repo}
}

func (h *QuotaHandler) Check(c *gin.Context) {
	var req model.QuotaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	status, err := h.repo.Check(c.Request.Context(), req.UserID, req.Model)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}

func (h *QuotaHandler) Consume(c *gin.Context) {
	var req model.QuotaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Tokens <= 0 {
		req.Tokens = 1
	}
	status, err := h.repo.Consume(c.Request.Context(), req.UserID, req.Model, req.Tokens)
	if err != nil {
		c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error(), "status": status})
		return
	}
	c.JSON(http.StatusOK, status)
}

func (h *QuotaHandler) GetStatus(c *gin.Context) {
	userID := c.Param("userId")
	statuses, err := h.repo.GetStatus(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"user_id": userID, "models": statuses})
}

func (h *QuotaHandler) Reset(c *gin.Context) {
	var req model.QuotaRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.Reset(c.Request.Context(), req.UserID, req.Model); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "reset"})
}