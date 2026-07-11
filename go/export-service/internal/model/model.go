package model

type ExportRequest struct {
	Format   string   `json:"format" binding:"required"`
	Title    string   `json:"title" binding:"required"`
	Content  string   `json:"content" binding:"required"`
	Chapters []ChapterDoc `json:"chapters,omitempty"`
}

type ChapterDoc struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

const (
	FormatMarkdown = "markdown"
	FormatPDF      = "pdf"
	FormatEPUB     = "epub"
	FormatTXT      = "txt"
)