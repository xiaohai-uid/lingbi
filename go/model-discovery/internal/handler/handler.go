package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/xiaohai-uid/lingbi/model-discovery/internal/models"
	"github.com/xiaohai-uid/lingbi/model-discovery/internal/checker"
)

type Handler struct {
	registry *models.Registry
	checker  *checker.Checker
}

func NewHandler(r *models.Registry, c *checker.Checker) *Handler {
	return &Handler{registry: r, checker: c}
}

// TestRequest 连接测试请求
type TestRequest struct {
	Endpoint string `json:"endpoint" binding:"required"`
	APIKey   string `json:"api_key"`
	Model    string `json:"model" binding:"required"`
}

// RecommendRequest 推荐请求
type RecommendRequest struct {
	Need       string `json:"need"`        // writing / analysis / speed
	NeedAPIKey bool   `json:"need_api_key"`
}

// ListFree 获取免费模型列表
func (h *Handler) ListFree(c *gin.Context) {
	models := h.registry.ListFree()
	c.JSON(http.StatusOK, gin.H{
		"models": models,
		"total":  len(models),
	})
}

// TestConnection 测试模型连接
func (h *Handler) TestConnection(c *gin.Context) {
	var req TestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result := h.checker.TestConnection(req.Endpoint, req.APIKey, req.Model)
	c.JSON(http.StatusOK, gin.H{
		"test_result": result,
	})
}

// Recommend 推荐模型
func (h *Handler) Recommend(c *gin.Context) {
	var req RecommendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		req = RecommendRequest{Need: "writing", NeedAPIKey: false}
	}

	recommended := h.registry.Recommend(req.Need, req.NeedAPIKey)
	c.JSON(http.StatusOK, gin.H{
		"recommendations": recommended,
		"total":           len(recommended),
	})
}
