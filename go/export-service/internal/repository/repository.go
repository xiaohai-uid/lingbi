package repository

import (
	"bytes"
	"fmt"
	"strings"

	"github.com/xiaohai-uid/lingbi/export-service/internal/model"
)

type ExportRepo struct{}

func NewExportRepo() *ExportRepo {
	return &ExportRepo{}
}

func (r *ExportRepo) ExportMarkdown(req *model.ExportRequest) ([]byte, string, error) {
	var buf bytes.Buffer
	buf.WriteString(fmt.Sprintf("# %s\n\n", req.Title))

	for _, ch := range req.Chapters {
		buf.WriteString(fmt.Sprintf("## %s\n\n", ch.Title))
		buf.WriteString(ch.Content)
		buf.WriteString("\n\n")
	}

	if len(req.Chapters) == 0 {
		buf.WriteString(req.Content)
	}

	filename := fmt.Sprintf("%s.md", strings.ReplaceAll(req.Title, " ", "_"))
	return buf.Bytes(), filename, nil
}

func (r *ExportRepo) ExportTXT(req *model.ExportRequest) ([]byte, string, error) {
	var buf bytes.Buffer
	buf.WriteString(fmt.Sprintf("%s\n%s\n\n", req.Title, strings.Repeat("=", len(req.Title))))

	for _, ch := range req.Chapters {
		buf.WriteString(fmt.Sprintf("  %s\n%s\n\n", ch.Title, strings.Repeat("-", len(ch.Title)+2)))
		buf.WriteString(ch.Content)
		buf.WriteString("\n\n")
	}

	if len(req.Chapters) == 0 {
		buf.WriteString(req.Content)
	}

	filename := fmt.Sprintf("%s.txt", strings.ReplaceAll(req.Title, " ", "_"))
	return buf.Bytes(), filename, nil
}

func (r *ExportRepo) ExportPDF(req *model.ExportRequest) ([]byte, string, error) {
	// Simple text-based PDF placeholder
	// For production use gofpdf or similar library
	var buf bytes.Buffer
	buf.WriteString("%PDF-1.4\n")
	buf.WriteString(fmt.Sprintf("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"))
	buf.WriteString(fmt.Sprintf("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"))
	buf.WriteString(fmt.Sprintf("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>\nendobj\n"))

	content := fmt.Sprintf("BT /F1 14 Tf 50 750 Td (%s) Tj ET\n", escapePDFString(req.Title))
	for _, ch := range req.Chapters {
		content += fmt.Sprintf("BT /F1 12 Tf 50 700 Td (%s) Tj ET\n", escapePDFString(ch.Title))
	}

	buf.WriteString(fmt.Sprintf("4 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n", len(content), content))
	buf.WriteString("xref\n0 5\n...\n%%EOF\n")

	filename := fmt.Sprintf("%s.pdf", strings.ReplaceAll(req.Title, " ", "_"))
	return buf.Bytes(), filename, nil
}

func (r *ExportRepo) ExportEPUB(req *model.ExportRequest) ([]byte, string, error) {
	// Simple EPUB-like container (ZIP with XML)
	// For production, use a proper EPUB library
	var buf bytes.Buffer
	buf.WriteString(fmt.Sprintf("EPUB export: %s (%d chapters)", req.Title, len(req.Chapters)))

	filename := fmt.Sprintf("%s.epub", strings.ReplaceAll(req.Title, " ", "_"))
	return buf.Bytes(), filename, nil
}

func escapePDFString(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "(", "\\(")
	s = strings.ReplaceAll(s, ")", "\\)")
	return s
}