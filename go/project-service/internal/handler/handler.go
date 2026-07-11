package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/project-service/internal/model"
	"github.com/xiaohai-uid/lingbi/project-service/internal/repository"
)

type ProjectHandler struct {
	repo *repository.ProjectRepo
}

func NewProjectHandler(repo *repository.ProjectRepo) *ProjectHandler {
	return &ProjectHandler{repo: repo}
}

// ---- World ----

func (h *ProjectHandler) CreateWorld(c *gin.Context) {
	var w model.World
	if err := c.ShouldBindJSON(&w); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.CreateWorld(c.Request.Context(), &w); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, w)
}

func (h *ProjectHandler) GetWorld(c *gin.Context) {
	w, err := h.repo.GetWorld(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, w)
}

func (h *ProjectHandler) ListWorlds(c *gin.Context) {
	worlds, err := h.repo.ListWorlds(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, worlds)
}

func (h *ProjectHandler) UpdateWorld(c *gin.Context) {
	var w model.World
	if err := c.ShouldBindJSON(&w); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	w.ID = c.Param("id")
	if err := h.repo.UpdateWorld(c.Request.Context(), &w); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, w)
}

func (h *ProjectHandler) DeleteWorld(c *gin.Context) {
	if err := h.repo.DeleteWorld(c.Request.Context(), c.Param("id")); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}

// ---- Work ----

func (h *ProjectHandler) CreateWork(c *gin.Context) {
	var w model.Work
	if err := c.ShouldBindJSON(&w); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.CreateWork(c.Request.Context(), &w); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, w)
}

func (h *ProjectHandler) GetWork(c *gin.Context) {
	w, err := h.repo.GetWork(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, w)
}

func (h *ProjectHandler) ListWorks(c *gin.Context) {
	works, err := h.repo.ListWorks(c.Request.Context(), c.Query("world_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, works)
}

// ---- Volume ----

func (h *ProjectHandler) CreateVolume(c *gin.Context) {
	var v model.Volume
	if err := c.ShouldBindJSON(&v); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.CreateVolume(c.Request.Context(), &v); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, v)
}

func (h *ProjectHandler) ListVolumes(c *gin.Context) {
	vols, err := h.repo.ListVolumes(c.Request.Context(), c.Query("work_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, vols)
}

// ---- Chapter ----

func (h *ProjectHandler) CreateChapter(c *gin.Context) {
	var ch model.Chapter
	if err := c.ShouldBindJSON(&ch); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.CreateChapter(c.Request.Context(), &ch); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, ch)
}

func (h *ProjectHandler) ListChapters(c *gin.Context) {
	chs, err := h.repo.ListChapters(c.Request.Context(), c.Query("volume_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, chs)
}

// ---- Scene ----

func (h *ProjectHandler) CreateScene(c *gin.Context) {
	var s model.Scene
	if err := c.ShouldBindJSON(&s); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.repo.CreateScene(c.Request.Context(), &s); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, s)
}

func (h *ProjectHandler) ListScenes(c *gin.Context) {
	scenes, err := h.repo.ListScenes(c.Request.Context(), c.Query("chapter_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, scenes)
}

// ---- Tree ----

func (h *ProjectHandler) GetWorldTree(c *gin.Context) {
	tree, err := h.repo.GetWorldTree(c.Request.Context(), c.Param("world_id"))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, tree)
}