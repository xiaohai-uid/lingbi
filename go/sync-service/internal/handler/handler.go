package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/sync-service/internal/model"
	"github.com/xiaohai-uid/lingbi/sync-service/internal/repository"
)

type SyncHandler struct {
	repo *repository.SyncRepo
}

func NewSyncHandler(repo *repository.SyncRepo) *SyncHandler {
	return &SyncHandler{repo: repo}
}

func (h *SyncHandler) GetStatus(c *gin.Context) {
	c.JSON(http.StatusOK, h.repo.GetStatus())
}

func (h *SyncHandler) GetConfig(c *gin.Context) {
	c.JSON(http.StatusOK, h.repo.GetConfig())
}

func (h *SyncHandler) SetConfig(c *gin.Context) {
	var cfg model.SyncConfig
	if err := c.ShouldBindJSON(&cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.SetConfig(cfg); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "config updated"})
}

func (h *SyncHandler) TriggerSync(c *gin.Context) {
	status, err := h.repo.TriggerSync()
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}