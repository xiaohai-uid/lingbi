package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/timeline-service/internal/model"
	"github.com/xiaohai-uid/lingbi/timeline-service/internal/repository"
)

type TimelineHandler struct {
	repo *repository.TimelineRepo
}

func NewTimelineHandler(repo *repository.TimelineRepo) *TimelineHandler {
	return &TimelineHandler{repo: repo}
}

func (h *TimelineHandler) Create(c *gin.Context) {
	var e model.TimelineEvent
	if err := c.ShouldBindJSON(&e); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.Create(c.Request.Context(), &e); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, e)
}

func (h *TimelineHandler) Get(c *gin.Context) {
	e, err := h.repo.Get(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, e)
}

func (h *TimelineHandler) List(c *gin.Context) {
	events, err := h.repo.List(c.Request.Context(), c.Query("world_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, events)
}

func (h *TimelineHandler) Update(c *gin.Context) {
	var e model.TimelineEvent
	if err := c.ShouldBindJSON(&e); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	e.ID = c.Param("id")
	if err := h.repo.Update(c.Request.Context(), &e); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, e)
}

func (h *TimelineHandler) Delete(c *gin.Context) {
	if err := h.repo.Delete(c.Request.Context(), c.Param("id")); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}