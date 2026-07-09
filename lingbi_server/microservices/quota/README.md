# Quota Service

A microservice for managing API rate limiting using the Token Bucket algorithm.

## Features

- **GET /status** - Check current quota status
- **POST /consume** - Consume one token from quota
- **PUT /reset** - Reset quota to daily limit

## Configuration

- **Port**: 8088
- **Daily Limit**: 100 requests
- **Storage**: JSON file (quota_data.json)

## Usage

Start the service:
```bash
dart run main.dart
```

Run tests:
```bash
dart test
```

## Response Examples

### Status
```json
{
  "remaining": 95,
  "limit": 100,
  "lastRefill": "2024-07-04T10:00:00.000Z",
  "resetIn": "95 tokens available"
}
```

### Consume Success
```json
{
  "success": true,
  "message": "Token consumed successfully",
  "remaining": 94
}
```

### Consume Failed
```json
{
  "success": false,
  "message": "Daily limit reached",
  "remaining": 0
}
```

### Reset
```json
{
  "success": true,
  "message": "Quota reset successfully",
  "remaining": 100,
  "limit": 100
}
```
