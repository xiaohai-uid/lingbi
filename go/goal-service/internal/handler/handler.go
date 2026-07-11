package handler

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/goal-service/internal/storage"
)

type Handler struct {
	store *storage.Storage
}

func NewHandler(s *storage.Storage) *Handler {
	return &Handler{store: s}
}

type RecordRequest struct {
	WorldID    string `json:"world_id" binding:"required"`
	WordCount  int    `json:"word_count" binding:"required"`
	Minutes    int    `json:"minutes_spent"`
	AICalls    int    `json:"ai_call_count"`
}

type SetGoalRequest struct {
	WorldID     string `json:"world_id" binding:"required"`
	Type        string `json:"type" binding:"required"`
	TargetWords int    `json:"target_word_count" binding:"required"`
}

func (h *Handler) RecordWriting(c *gin.Context) {
	var req RecordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	today := time.Now().Format("2006-01-02")
	if err := h.store.RecordWriting(req.WorldID, today, req.WordCount, req.Minutes, req.AICalls); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "recorded", "date": today})
}

func (h *Handler) GetTodayStats(c *gin.Context) {
	worldID := c.Query("world_id")
	if worldID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "world_id required"})
		return
	}
	today := time.Now().Format("2006-01-02")
	stat, err := h.store.GetTodayStats(worldID, today)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if stat == nil {
		c.JSON(http.StatusOK, gin.H{"word_count": 0, "session_count": 0})
		return
	}
	c.JSON(http.StatusOK, stat)
}

func (h *Handler) GetMonthStats(c *gin.Context) {
	worldID := c.Query("world_id")
	year := c.DefaultQuery("year", time.Now().Format("2006"))
	month := c.DefaultQuery("month", time.Now().Format("01"))
	if worldID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "world_id required"})
		return
	}
	stats, err := h.store.GetMonthStats(worldID, year+"-"+month)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"stats": stats, "total": len(stats)})
}

func (h *Handler) GetStreak(c *gin.Context) {
	worldID := c.Query("world_id")
	if worldID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "world_id required"})
		return
	}
	streak, err := h.store.GetStreak(worldID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"streak": streak})
}

func (h *Handler) SetGoal(c *gin.Context) {
	var req SetGoalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.store.SetGoal(req.WorldID, req.Type, req.TargetWords); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "goal_set"})
}

func (h *Handler) GetProgress(c *gin.Context) {
	worldID := c.Query("world_id")
	if worldID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "world_id required"})
		return
	}
	goal, err := h.store.GetActiveGoal(worldID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if goal == nil {
		c.JSON(http.StatusOK, gin.H{"has_goal": false})
		return
	}
	today := time.Now().Format("2006-01-02")
	stat, _ := h.store.GetTodayStats(worldID, today)
	currentWords := 0
	if stat != nil {
		currentWords = stat.WordCount
	}
	percentage := 0.0
	if goal.TargetWords > 0 {
		percentage = float64(currentWords) / float64(goal.TargetWords) * 100
	}
	streak, _ := h.store.GetStreak(worldID)

	c.JSON(http.StatusOK, gin.H{
		"has_goal":          true,
		"type":              goal.Type,
		"target_word_count": goal.TargetWords,
		"current_word_count": currentWords,
		"percentage":        percentage,
		"streak":            streak,
	})
}
