package summarizer

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Summarizer LLM 搜索摘要生成器
type Summarizer struct {
	aiProviderURL string
	client        *http.Client
}

func NewSummarizer(aiProviderURL string) *Summarizer {
	return &Summarizer{
		aiProviderURL: aiProviderURL,
		client:        &http.Client{Timeout: 60 * time.Second},
	}
}

// Summarize 对搜索结果生成 AI 摘要
func (s *Summarizer) Summarize(ctx *http.Request, query string, results []map[string]interface{}) (string, error) {
	// 构建 prompt
	resultsJSON, _ := json.MarshalIndent(results, "", "  ")
	prompt := fmt.Sprintf(
		`你是一个搜索摘要助手。根据以下搜索结果，为用户的问题生成一个简洁、信息密集的摘要。

用户问题: %s

搜索结果:
%s

请输出:
1. 核心答案（直接回答用户问题）
2. 关键信息点（列表形式）
3. 来源链接（引用搜索结果中的 URL）

使用中文输出，保持客观准确。`,
		query, string(resultsJSON),
	)

	payload := map[string]interface{}{
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
		"temperature": 0.3,
		"max_tokens":  2048,
	}

	body, _ := json.Marshal(payload)
	resp, err := s.client.Post(
		s.aiProviderURL+"/api/v1/ai/chat",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return "", fmt.Errorf("AI call failed: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", err
	}

	if len(result.Choices) > 0 {
		return result.Choices[0].Message.Content, nil
	}
	return "", fmt.Errorf("no response from AI")
}
