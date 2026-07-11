package checker

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// Checker 模型连接测试器
type Checker struct {
	client *http.Client
}

func NewChecker() *Checker {
	return &Checker{
		client: &http.Client{Timeout: 15 * time.Second},
	}
}

// TestResult 测试结果
type TestResult struct {
	ModelID  string `json:"model_id"`
	Success  bool   `json:"success"`
	Latency  int64  `json:"latency_ms"`
	Error    string `json:"error,omitempty"`
}

// TestConnection 测试模型连接
func (c *Checker) TestConnection(endpoint, apiKey, model string) *TestResult {
	result := &TestResult{ModelID: model}

	start := time.Now()

	payload := map[string]interface{}{
		"model": model,
		"messages": []map[string]string{
			{"role": "user", "content": "Hi"},
		},
		"max_tokens": 5,
	}

	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", endpoint, bytes.NewReader(body))
	if err != nil {
		result.Error = fmt.Sprintf("request creation failed: %v", err)
		return result
	}

	req.Header.Set("Content-Type", "application/json")
	if apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+apiKey)
	}

	resp, err := c.client.Do(req)
	if err != nil {
		result.Error = fmt.Sprintf("connection failed: %v", err)
		return result
	}
	defer resp.Body.Close()

	result.Latency = time.Since(start).Milliseconds()

	if resp.StatusCode == 200 || resp.StatusCode == 401 {
		// 200=成功, 401=API Key 无效但连接成功
		result.Success = true
		if resp.StatusCode == 401 {
			result.Error = "API Key 无效，但服务端连接正常"
		}
	} else {
		result.Error = fmt.Sprintf("HTTP %d: unexpected status", resp.StatusCode)
	}

	return result
}
