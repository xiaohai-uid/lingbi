package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/xiaohai-uid/lingbi/search-service/internal/search"
	"github.com/xiaohai-uid/lingbi/search-service/internal/extractor"
	"github.com/xiaohai-uid/lingbi/search-service/internal/summarizer"
)

// Handler HTTP handlers
type Handler struct {
	searcher  *search.Searcher
	extractor *extractor.Extractor
	summarizer *summarizer.Summarizer
}

// WebSearchRequest 搜索请求
type WebSearchRequest struct {
	Query      string `json:"query" binding:"required"`
	MaxResults int    `json:"max_results"`
	Summary    bool   `json:"summary"`
}

func NewHandler(s *search.Searcher, e *extractor.Extractor, sm *summarizer.Summarizer) *Handler {
	return &Handler{
		searcher:   s,
		extractor:  e,
		summarizer: sm,
	}
}

// WebSearch AI 联网搜索
func (h *Handler) WebSearch(c *gin.Context) {
	var req WebSearchRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.MaxResults <= 0 || req.MaxResults > 10 {
		req.MaxResults = 5
	}

	// 1. 执行搜索
	results, err := h.searcher.Search(c.Request.Context(), req.Query, req.MaxResults)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "search failed",
			"details": err.Error(),
		})
		return
	}

	// 2. 提取内容（如果请求了摘要则提取前3个结果）
	var resultItems []map[string]interface{}
	for i, r := range results {
		item := map[string]interface{}{
			"title":   r.Title,
			"url":     r.URL,
			"snippet": r.Snippet,
		}
		if req.Summary && i < 3 {
			extracted, err := h.extractor.Extract(c.Request.Context(), r.URL)
			if err == nil {
				item["content"] = extracted.Content
			}
		}
		resultItems = append(resultItems, item)
	}

	// 3. 生成摘要
	var summary string
	if req.Summary && h.summarizer != nil {
		summary, _ = h.summarizer.Summarize(c.Request, req.Query, resultItems)
	}

	c.JSON(http.StatusOK, gin.H{
		"query":   req.Query,
		"results": resultItems,
		"summary": summary,
	})
}
