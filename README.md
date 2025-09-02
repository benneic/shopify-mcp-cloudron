# Shopify MCP Server for Cloudron

A Cloudron package for the Shopify Development MCP Server.

## Features

- Runs the latest `@shopify/dev-mcp` server
- HTTP/JSON-RPC endpoint for remote access (compatible with n8n, API clients)
- Optional authentication (Header or OAuth2Bearer)
- Cloudron-native configuration management
- Health monitoring and automatic restart capabilities

## Installation

### Prerequisites

- Cloudron instance running
- Cloudron CLI installed: `npm install -g cloudron`

### Build and Install

```bash
# Clone this repository
git clone https://github.com/your-repo/shopify-mcp-cloudron
cd shopify-mcp-cloudron

# Login to your Cloudron instance
cloudron login my.cloudron.domain

# Build the app (no registry push needed for local deployment)
cloudron build --no-push

# Install directly to your Cloudron
cloudron install --location mcp.yourdomain.com
```

### Alternative: Manual Package Installation

```bash
# Build and package
cloudron build

# Install from package file
cloudron install --location mcp.yourdomain.com --image com.shopify.mcp-server@1.0.0.tar.gz
```

## Configuration

Configure authentication and server settings through Cloudron's environment variables.

### Setting Environment Variables

1. **Via Cloudron Dashboard:**
   - Go to your app's settings in the Cloudron dashboard
   - Navigate to the "Environment" tab
   - Add or modify environment variables as needed
   - Click "Save" and restart the app

2. **Via Cloudron CLI:**
   ```bash
   # Set authentication type
   cloudron env set AUTH_TYPE header
   
   # Set authentication token
   cloudron env set AUTH_TOKEN your-secret-token
   
   # Set custom header name (optional)
   cloudron env set AUTH_HEADER_NAME X-API-Key
   
   # Restart the app to apply changes
   cloudron restart
   ```

### Available Environment Variables

- `AUTH_TYPE`: Authentication method
  - `header` - Use header-based authentication
  - `oauth2bearer` - Use OAuth2 Bearer token authentication
  - Empty/unset - No authentication required
- `AUTH_TOKEN`: Authentication token (required if AUTH_TYPE is set)
- `AUTH_HEADER_NAME`: Header name for authentication (default: `Authorization`)
- `PORT`: Server port (default: `8080`, automatically managed by Cloudron)
- `OPT_OUT_INSTRUMENTATION`: Disable telemetry (default: `false`)
- `POLARIS_UNIFIED`: Enable Polaris unified mode (default: `false`)
- `LIQUID`: Enable Liquid template support (default: `false`)
- `LIQUID_VALIDATION_MODE`: Liquid validation mode (default: `partial`)

### Authentication Examples

**Header Authentication:**
```bash
cloudron env set AUTH_TYPE header
cloudron env set AUTH_TOKEN your-api-key-here
cloudron env set AUTH_HEADER_NAME X-API-Key
cloudron restart
```

**OAuth2 Bearer Authentication:**
```bash
cloudron env set AUTH_TYPE oauth2bearer
cloudron env set AUTH_TOKEN your-bearer-token-here
cloudron restart
```

**No Authentication:**
```bash
cloudron env unset AUTH_TYPE
cloudron env unset AUTH_TOKEN
cloudron restart
```

## Updating the App

To update an existing installation:

```bash
# Make your changes to the code
# Rebuild the app
cloudron build --no-push

# Update the running app
cloudron update --app mcp.yourdomain.com
```


## Usage

Once installed, the MCP server will be available at your Cloudron app URL with HTTP endpoints for remote access.

### HTTP Endpoints

- **MCP Endpoint**: `https://your-app-url/mcp` (POST for JSON-RPC requests, GET for server info)
- **Health Check**: `https://your-app-url/health` (GET for server status)

### Connecting from n8n

In n8n's AI Agent node, configure the endpoint setting:

```
Endpoint URL: https://your-app-url/mcp
Method: POST
Content-Type: application/json
```

### JSON-RPC Request Format

Send POST requests to `/mcp` with JSON-RPC 2.0 format:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "n8n",
      "version": "1.0.0"
    }
  }
}
```

### Authentication

If authentication is configured, include the appropriate header:

```bash
# Header authentication
Authorization: your-api-key

# OAuth2 Bearer authentication  
Authorization: Bearer your-token
```

## Health Check

The server provides a health check endpoint at `/health` for monitoring.