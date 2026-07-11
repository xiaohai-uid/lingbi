package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/xiaohai-uid/lingbi/document-service/internal/model"
	"github.com/xiaohai-uid/lingbi/document-service/internal/repository"
)

type DocumentHandler struct {
	repo *repository.DocumentRepo
}

func NewDocumentHandler(repo *repository.DocumentRepo) *DocumentHandler {
	return &DocumentHandler{repo: repo}
}

func (h *DocumentHandler) Get(c *gin.Context) {
	doc, err := h.repo.Get(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, doc)
}

func (h *DocumentHandler) Save(c *gin.Context) {
	var doc model.Document
	if err := c.ShouldBindJSON(&doc); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if doc.ID == "" {
		doc.ID = uuid.New().String()
	}
	if err := h.repo.Save(c.Request.Context(), &doc); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, doc)
}

func (h *DocumentHandler) Search(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query required"})
		return
	}
	docs, err := h.repo.Search(c.Request.Context(), query, 10)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, docs)
}

func (h *DocumentHandler) GetWordCount(c *gin.Context) {
	count, err := h.repo.GetWordCount(c.Request.Context(), c.Param("id"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"word_count": count})
}