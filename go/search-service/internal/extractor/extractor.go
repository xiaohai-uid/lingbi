package extractor

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

// ExtractResult 提取结果
type ExtractResult struct {
	URL     string `json:"url"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

// Extractor 网页内容提取器
type Extractor struct {
	client *http.Client
}

func NewExtractor() *Extractor {
	return &Extractor{
		client: &http.Client{Timeout: 10 * time.Second},
	}
}

// Extract 抓取并提取网页正文
func (e *Extractor) Extract(ctx context.Context, urlStr string) (*ExtractResult, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", urlStr, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml")

	resp, err := e.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024)) // 1MB limit
	if err != nil {
		return nil, err
	}

	html := string(body)
	title := extractTitle(html)
	content := extractContent(html)

	return &ExtractResult{
		URL:     urlStr,
		Title:   title,
		Content: content,
	}, nil
}

func extractTitle(html string) string {
	re := regexp.MustCompile(`<title[^>]*>([^<]+)</title>`)
	matches := re.FindStringSubmatch(html)
	if len(matches) > 1 {
		return strings.TrimSpace(matches[1])
	}
	return ""
}

func extractContent(html string) string {
	// 移除 script 和 style 标签
	re := regexp.MustCompile(`(?s)<script[^>]*>.*?</script>|<style[^>]*>.*?</style>`)
	html = re.ReplaceAllString(html, "")

	// 提取文本内容
	re = regexp.MustCompile(`<[^>]+>`)
	text := re.ReplaceAllString(html, " ")

	// 合并空白
	re = regexp.MustCompile(`\s+`)
	text = re.ReplaceAllString(text, " ")

	// 分段
	lines := strings.Split(text, "\n")
	var clean []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if len(trimmed) > 20 { // 过滤短行
			clean = append(clean, trimmed)
		}
	}

	result := strings.Join(clean, "\n")
	if len(result) > 5000 {
		result = result[:5000] + "..."
	}
	return result
}
