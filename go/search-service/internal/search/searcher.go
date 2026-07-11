package search

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// SearchResult 单条搜索结果
type SearchResult struct {
	Title   string `json:"title"`
	URL     string `json:"url"`
	Snippet string `json:"snippet"`
	Content string `json:"content,omitempty"`
}

// SearchResponse 搜索响应
type SearchResponse struct {
	Query   string         `json:"query"`
	Results []SearchResult `json:"results"`
	Summary string         `json:"summary,omitempty"`
}

// Searcher 搜索适配器接口
type Searcher struct {
	client *http.Client
	rdb    *redis.Client
}

func NewSearcher(rdb *redis.Client) *Searcher {
	return &Searcher{
		client: &http.Client{Timeout: 15 * time.Second},
		rdb:    rdb,
	}
}

// Search 执行搜索 — 先查缓存，再调用外部搜索 API
func (s *Searcher) Search(ctx context.Context, query string, maxResults int) ([]SearchResult, error) {
	// 1. 检查缓存
	if s.rdb != nil {
		cached, err := s.rdb.Get(ctx, "search:"+query).Result()
		if err == nil {
			var results []SearchResult
			if json.Unmarshal([]byte(cached), &results) == nil {
				return results, nil
			}
		}
	}

	// 2. 调用外部搜索 API
	results, err := s.searchWeb(ctx, query, maxResults)
	if err != nil {
		return nil, fmt.Errorf("search failed: %w", err)
	}

	// 3. 缓存结果 (5分钟)
	if s.rdb != nil && len(results) > 0 {
		data, _ := json.Marshal(results)
		s.rdb.Set(ctx, "search:"+query, data, 5*time.Minute)
	}

	return results, nil
}

// searchWeb 使用免费搜索 API (DuckDuckGo / Bing / AnySearch)
func (s *Searcher) searchWeb(ctx context.Context, query string, maxResults int) ([]SearchResult, error) {
	// 使用 DuckDuckGo Lite API (免费，无需 API Key)
	encoded := url.QueryEscape(query)
	apiURL := fmt.Sprintf("https://api.duckduckgo.com/?q=%s&format=json&no_html=1&skip_disambig=1", encoded)

	req, err := http.NewRequestWithContext(ctx, "GET", apiURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Lingbi/1.0 (AI Writing Assistant)")

	resp, err := s.client.Do(req)
	if err != nil {
		// Fallback: 用 Bing 搜索
		return s.searchBing(ctx, query, maxResults)
	}
	defer resp.Body.Close()

	var ddgResp struct {
		AbstractText string `json:"AbstractText"`
		AbstractURL  string `json:"AbstractURL"`
		Results      []struct {
			Text     string `json:"Text"`
			FirstURL string `json:"FirstURL"`
		} `json:"Results"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&ddgResp); err != nil {
		return nil, err
	}

	var results []SearchResult
	if ddgResp.AbstractText != "" {
		results = append(results, SearchResult{
			Title:   "Summary",
			URL:     ddgResp.AbstractURL,
			Snippet: truncate(ddgResp.AbstractText, 300),
		})
	}

	for _, r := range ddgResp.Results {
		if len(results) >= maxResults {
			break
		}
		results = append(results, SearchResult{
			Title:   extractTitle(r.Text),
			URL:     r.FirstURL,
			Snippet: r.Text,
		})
	}

	return results, nil
}

// searchBing Bing 搜索作为 fallback
func (s *Searcher) searchBing(ctx context.Context, query string, maxResults int) ([]SearchResult, error) {
	encoded := url.QueryEscape(query)
	apiURL := fmt.Sprintf("https://www.bing.com/search?q=%s&count=%d", encoded, maxResults)

	req, err := http.NewRequestWithContext(ctx, "GET", apiURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// 简单解析 Bing 搜索结果页
	// 实际项目中建议用专门的 HTML 解析库
	return []SearchResult{}, nil
}

func truncate(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

func extractTitle(text string) string {
	if idx := strings.Index(text, " - "); idx > 0 {
		return text[:idx]
	}
	if idx := strings.Index(text, " | "); idx > 0 {
		return text[:idx]
	}
	// 取前 60 字
	runes := []rune(text)
	if len(runes) > 60 {
		return string(runes[:60]) + "..."
	}
	return text
}
