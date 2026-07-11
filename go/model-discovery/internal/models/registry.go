package models

import "fmt"

// ModelInfo 模型信息
type ModelInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Provider    string `json:"provider"`
	Type        string `json:"type"`       // chat / reasoning / embedding
	IsFree      bool   `json:"is_free"`
	Description string `json:"description"`
	Endpoint    string `json:"endpoint"`    // API 端点
	DocsURL     string `json:"docs_url,omitempty"`
}

// Registry 模型注册表
type Registry struct {
	models []ModelInfo
}

func NewRegistry() *Registry {
	r := &Registry{}
	r.initBuiltinModels()
	return r
}

func (r *Registry) initBuiltinModels() {
	r.models = []ModelInfo{
		{
			ID: "siliconflow-qwen2.5-7b",
			Name: "Qwen2.5-7B-Instruct",
			Provider: "SiliconFlow",
			Type: "chat",
			IsFree: true,
			Description: "通义千问2.5 7B 免费版，适合日常写作辅助",
			Endpoint: "https://api.siliconflow.cn/v1/chat/completions",
		},
		{
			ID: "siliconflow-deepseek-r1",
			Name: "DeepSeek-R1",
			Provider: "SiliconFlow",
			Type: "reasoning",
			IsFree: true,
			Description: "DeepSeek R1 推理模型，适合复杂情节分析",
			Endpoint: "https://api.siliconflow.cn/v1/chat/completions",
		},
		{
			ID: "deepseek-chat",
			Name: "DeepSeek-V3",
			Provider: "DeepSeek",
			Type: "chat",
			IsFree: true,
			Description: "DeepSeek 最新版对话模型，综合能力强",
			Endpoint: "https://api.deepseek.com/v1/chat/completions",
		},
		{
			ID: "zhipu-glm4-flash",
			Name: "GLM-4-Flash",
			Provider: "智谱AI",
			Type: "chat",
			IsFree: true,
			Description: "智谱 GLM-4 Flash 免费版，速度快",
			Endpoint: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
		},
		{
			ID: "kimi-moonshot-v1",
			Name: "Moonshot-v1-8K",
			Provider: "Kimi",
			Type: "chat",
			IsFree: true,
			Description: "Kimi 月之暗面 8K 上下文，适合长文本",
			Endpoint: "https://api.moonshot.cn/v1/chat/completions",
		},
		{
			ID: "minimax-abab6.5s",
			Name: "abab6.5s",
			Provider: "MiniMax",
			Type: "chat",
			IsFree: true,
			Description: "MiniMax 最新版，创作风格多样",
			Endpoint: "https://api.minimax.chat/v1/text/chatcompletion_v2",
		},
		{
			ID: "openai-gpt4o-mini",
			Name: "GPT-4o-mini",
			Provider: "OpenAI",
			Type: "chat",
			IsFree: false,
			Description: "OpenAI GPT-4o mini，需 API Key",
			Endpoint: "https://api.openai.com/v1/chat/completions",
		},
	}
}

// ListFree 获取所有免费模型
func (r *Registry) ListFree() []ModelInfo {
	var free []ModelInfo
	for _, m := range r.models {
		if m.IsFree {
			free = append(free, m)
		}
	}
	return free
}

// ListAll 获取所有模型
func (r *Registry) ListAll() []ModelInfo {
	return r.models
}

// GetByID 根据 ID 获取模型
func (r *Registry) GetByID(id string) (*ModelInfo, error) {
	for _, m := range r.models {
		if m.ID == id {
			return &m, nil
		}
	}
	return nil, fmt.Errorf("model not found: %s", id)
}

// Recommend 根据用户需求推荐模型
func (r *Registry) Recommend(need string, needAPIKey bool) []ModelInfo {
	var candidates []ModelInfo
	for _, m := range r.models {
		if !needAPIKey && !m.IsFree {
			continue
		}
		switch need {
		case "writing":
			if m.Type == "chat" {
				candidates = append(candidates, m)
			}
		case "analysis":
			if m.Type == "reasoning" || m.Type == "chat" {
				candidates = append(candidates, m)
			}
		case "speed":
			if m.IsFree && m.Type == "chat" {
				candidates = append(candidates, m)
			}
		default:
			candidates = append(candidates, m)
		}
	}
	if len(candidates) > 3 {
		candidates = candidates[:3]
	}
	return candidates
}
