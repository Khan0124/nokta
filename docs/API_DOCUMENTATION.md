# Nokta POS API Documentation

## Base URL
```
Production: https://api.nokta-pos.com/api
Development: http://localhost:3001/api
```

## Authentication
All API requests require authentication using JWT tokens.

### Headers
```
Authorization: Bearer <token>
X-Tenant-ID: <tenant_id>
Content-Type: application/json
```

## API Endpoints

### Authentication

#### Login
```http
POST /auth/login
```

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@nokta-pos.com",
    "role": "admin"
  }
}
```

[Rest of API documentation content...]
