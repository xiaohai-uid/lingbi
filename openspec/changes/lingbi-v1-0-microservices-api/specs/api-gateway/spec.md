## ADDED Requirements

### Requirement: Centralized routing
The system SHALL provide a unified API Gateway that routes all HTTP requests from the Flutter client to the appropriate microservice based on URL path prefixes.

#### Scenario: Path-based routing
- **WHEN** a request arrives at /api/v1/project/list
- **THEN** the Gateway routes it to the Project service
- **AND** logs the request for monitoring

### Requirement: Request/response transformation
The Gateway SHALL normalize request and response formats between client and microservices, including content-type negotiation and error standardization.

#### Scenario: Error normalization
- **WHEN** a microservice returns an error
- **THEN** the Gateway transforms it into a standardized error response
- **AND** includes the original error code and message for debugging

### Requirement: Rate limiting at gateway
The Gateway SHALL implement rate limiting per user session to prevent abuse of any single microservice.

#### Scenario: Rate limit exceeded
- **WHEN** a client sends more than the configured request limit in a time window
- **THEN** the Gateway returns a 429 Too Many Requests response
- **AND** logs the rate limit violation