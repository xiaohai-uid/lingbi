## ADDED Requirements

### Requirement: OpenAI compatible adapter
The system SHALL provide a generic adapter that can connect to any model serving an OpenAI-compatible /v1/chat/completions API endpoint.

#### Scenario: Ollama connection
- **WHEN** user configures an Ollama model with baseUrl http://localhost:11434/v1
- **THEN** the adapter sends requests to that endpoint using the OpenAI protocol
- **AND** the response is parsed as a chat completion stream

### Requirement: Domestic LLM SDK wrappers
The system SHALL support at least 6 domestic Chinese LLM providers: 通义千问, 智谱 GLM, 百川, 月之暗面, 火山引擎, 商汤 SenseNova.

#### Scenario: Qwen model registration
- **WHEN** user adds 通义千问 API key and model name
- **THEN** the system can make chat requests to 通义千问's API
- **AND** handles rate limits and errors gracefully

### Requirement: Custom model configuration
Users SHALL be able to add, edit, and delete custom AI model configurations through the settings UI without modifying code.

#### Scenario: Adding a custom model
- **WHEN** user navigates to settings → AI Models → Add Custom Model
- **THEN** user can specify provider type, base URL, API key, and model name
- **AND** the configuration is saved and available for selection

## MODIFIED Requirements

### Requirement: AI Provider selection
**FROM:** Fixed list of 4 providers (free/deepseek/openai/claude)
**TO:** Dynamic provider list loaded from configuration + built-in providers

#### Scenario: Provider list update
- **WHEN** user adds a new custom model
- **THEN** the model appears in the model selector dropdown
- **AND** can be selected as the active model