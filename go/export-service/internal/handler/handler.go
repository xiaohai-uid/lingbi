package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/xiaohai-uid/lingbi/export-service/internal/model"
	"github.com/xiaohai-uid/lingbi/export-service/internal/repository"
)

type ExportHandler struct {
	repo *repository.ExportRepo
}

func NewExportHandler(repo *repository.ExportRepo) *ExportHandler {
	return &ExportHandler{repo: repo}
}

func (h *ExportHandler) Export(c *gin.Context) {
	format := c.Param("format")
	var req model.ExportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	req.Format = format

	var data []byte
	var filename string
	var err error

	switch format {
	case model.FormatMarkdown:
		data, filename, err = h.repo.ExportMarkdown(&req)
	case model.FormatPDF:
		data, filename, err = h.repo.ExportPDF(&req)
	case model.FormatEPUB:
		data, filename, err = h.repo.ExportEPUB(&req)
	case model.FormatTXT:
		data, filename, err = h.repo.ExportTXT(&req)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "unsupported format: " + format})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Disposition", "attachment; filename=\""+filename+"\"")
	c.Header("Content-Type", "application/octet-stream")
	c.Data(http.StatusOK, "application/octet-stream", data)
}