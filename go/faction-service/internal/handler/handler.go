package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/faction-service/internal/model"
	"github.com/xiaohai-uid/lingbi/faction-service/internal/repository"
)

type FactionHandler struct {
	repo *repository.FactionRepo
}

func NewFactionHandler(repo *repository.FactionRepo) *FactionHandler {
	return &FactionHandler{repo: repo}
}

func (h *FactionHandler) Create(c *gin.Context) {
	var f model.Faction
	if err := c.ShouldBindJSON(&f); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.Create(c.Request.Context(), &f); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, f)
}

func (h *FactionHandler) Get(c *gin.Context) {
	f, err := h.repo.Get(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, f)
}

func (h *FactionHandler) List(c *gin.Context) {
	factions, err := h.repo.List(c.Request.Context(), c.Query("world_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, factions)
}

func (h *FactionHandler) Update(c *gin.Context) {
	var f model.Faction
	if err := c.ShouldBindJSON(&f); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	f.ID = c.Param("id")
	if err := h.repo.Update(c.Request.Context(), &f); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, f)
}

func (h *FactionHandler) Delete(c *gin.Context) {
	if err := h.repo.Delete(c.Request.Context(), c.Param("id")); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

func (h *FactionHandler) AddMember(c *gin.Context) {
	var body struct {
		MemberID string `json:"member_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.AddMember(c.Request.Context(), c.Param("id"), body.MemberID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "member added"})
}

func (h *FactionHandler) RemoveMember(c *gin.Context) {
	var body struct {
		MemberID string `json:"member_id" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.RemoveMember(c.Request.Context(), c.Param("id"), body.MemberID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "member removed"})
}