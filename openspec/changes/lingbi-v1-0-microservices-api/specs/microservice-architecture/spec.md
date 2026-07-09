## ADDED Requirements

### Requirement: Service registry and discovery
The system SHALL maintain a local registry of all running microservices with their health status and endpoint information.

#### Scenario: Service registry initialization
- **WHEN** the application starts
- **THEN** all microservices register themselves with the registry
- **AND** the registry exposes a /health endpoint for each service

### Requirement: API Gateway routing
The system SHALL route all client requests through a unified API Gateway to the appropriate microservice.

#### Scenario: Request routing
- **WHEN** a client sends a request to /api/v1/ai/chat
- **THEN** the Gateway forwards it to the AI service on port 8081
- **AND** the response is returned to the client transparently

### Requirement: Service isolation
Each microservice SHALL run as an independent process with its own memory space and lifecycle.

#### Scenario: Service failure isolation
- **WHEN** the AI service crashes
- **THEN** other services (Document, Project) continue to operate normally
- **AND** the client receives a clear error message for AI-related requests

## MODIFIED Requirements

### Requirement: AI Provider interface
The AI Provider interface SHALL use HTTP-based API calls through the API Gateway instead of synchronous direct calls.
**FROM:** Synchronous AIProvider methods called directly from ServiceLocator
**TO:** HTTP-based API calls through the API Gateway

#### Scenario: AI chat via API
- **WHEN** the client sends a chat message
- **THEN** the AI service receives it via HTTP
- **AND** returns a streaming response through Server-Sent Events