package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/version-history/internal/repository"
)

type VersionHandler struct {
	repo *repository.VersionRepo
}

func NewVersionHandler(repo *repository.VersionRepo) *VersionHandler {
	return &VersionHandler{repo: repo}
}

func (h *VersionHandler) Snapshot(c *gin.Context) {
	var body struct {
		Content string `json:"content" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	snap, err := h.repo.Snapshot(c.Request.Context(), c.Param("docId"), body.Content)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, snap)
}

func (h *VersionHandler) GetHistory(c *gin.Context) {
	snaps, err := h.repo.GetHistory(c.Request.Context(), c.Param("docId"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, snaps)
}

func (h *VersionHandler) GetSnapshot(c *gin.Context) {
	v, _ := strconv.Atoi(c.Param("version"))
	snap, err := h.repo.GetSnapshot(c.Request.Context(), c.Param("docId"), v)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, snap)
}

func (h *VersionHandler) Diff(c *gin.Context) {
	v1, _ := strconv.Atoi(c.Query("v1"))
	v2, _ := strconv.Atoi(c.Query("v2"))
	if v1 <= 0 || v2 <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "v1 and v2 required"})
		return
	}
	result, err := h.repo.Diff(c.Request.Context(), c.Param("docId"), v1, v2)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, result)
}