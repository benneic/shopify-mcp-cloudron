# Shopify MCP Server - Cloudron Package

This is a Cloudron custom app package for running the Shopify Model Context Protocol (MCP) server.

## What is MCP?

The Model Context Protocol (MCP) is a protocol that enables AI assistants and development tools to interact with external systems like Shopify stores through a standardized interface.

## Package Structure

```
shopify-mcp-cloudron/
├── CloudronManifest.json   # Cloudron app metadata and configuration
├── Dockerfile              # Container definition for Cloudron
├── docker-compose.yml      # For local testing
├── README.md              # This file
├── icon.png               # App icon (256x256 PNG)
└── CHANGELOG.md           # Version history
```

## Prerequisites

- Cloudron instance (v7.4.0 or higher)
- Cloudron CLI tools installed
- Docker (for local testing)
- Shopify store and API credentials

## Building the Package

### 1. Local Testing

First, test the package locally using Docker Compose:

```bash
# Build and run locally
docker-compose up --build

# Test the health check
curl http://localhost:3000/

# Check logs
docker-compose logs -f
```

### 2. Create App Icon

Create a 256x256 PNG icon for your app and save it as `icon.png` in the package directory.

### 3. Build Cloudron Package

```bash
# Install Cloudron CLI if not already installed
npm install -g cloudron

# Login to your Cloudron instance
cloudron login my.cloudron.domain

# Build the package
cloudron build

# This creates a package file like: com.shopify.mcp-server@1.0.0.tar.gz
```

## Installation on Cloudron

### Method 1: Via Cloudron CLI

```bash
# Install the app
cloudron install --location mcp.yourdomain.com

# Or specify the package file
cloudron install --location mcp.yourdomain.com --image com.shopify.mcp-server@1.0.0.tar.gz
```

### Method 2: Via Cloudron Web Interface

1. Go to your Cloudron dashboard
2. Click "App Store" → "Install Custom App"
3. Upload the package file (com.shopify.mcp-server@1.0.0.tar.gz)
4. Configure the installation:
   - Choose a subdomain (e.g., mcp.yourdomain.com)
   - Set memory limit (recommended: 512MB minimum)
   - Configure environment variables if needed

## Configuration

### Environment Variables

After installation, configure these environment variables in the Cloudron app settings:

```bash
# Required for Shopify integration
SHOPIFY_API_KEY=your_api_key
SHOPIFY_API_SECRET=your_api_secret
SHOPIFY_STORE_DOMAIN=your-store.myshopify.com
SHOPIFY_ACCESS_TOKEN=your_access_token

# Optional
PORT=3000  # Default port
NODE_ENV=production
```

### Setting Environment Variables in Cloudron

1. Go to your Cloudron dashboard
2. Click on the installed Shopify MCP Server app
3. Go to "Configuration" → "Environment"
4. Add your environment variables
5. Click "Save" and restart the app

## Connecting to the MCP Server

Once installed, the MCP server will be available at:

- **HTTP Endpoint**: `https://mcp.yourdomain.com`
- **MCP Protocol**: `https://mcp.yourdomain.com:8080`

### Example Connection

```javascript
// Example Node.js client connection
const mcpClient = new MCPClient({
  endpoint: 'https://mcp.yourdomain.com:8080',
  protocol: 'mcp',
  auth: {
    // Your authentication details
  }
});
```

## Updating the Package

To update the app:

```bash
# Increment version in CloudronManifest.json
# Rebuild the package
cloudron build

# Update the installed app
cloudron update --app mcp.yourdomain.com --image com.shopify.mcp-server@1.1.0.tar.gz
```

## Monitoring and Logs

### View Logs

```bash
# Via CLI
cloudron logs --app mcp.yourdomain.com

# Or in the web interface
# Go to the app → Logs
```

### Health Checks

The app includes automatic health checks. If the service fails, Cloudron will automatically restart it.

## Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3000 and 8080 are not used by other apps
2. **Memory issues**: Increase memory limit if the app crashes
3. **API connection failures**: Verify Shopify API credentials
4. **Permission errors**: The app runs as non-root user (uid 1000)

### Debug Mode

Enable debug logging by setting:

```bash
DEBUG=* 
NODE_ENV=development
```

## Security Considerations

1. **API Credentials**: Store sensitive credentials as environment variables
2. **Network Access**: Configure firewall rules if needed
3. **SSL/TLS**: Cloudron automatically provides SSL certificates
4. **Updates**: Keep the package updated with latest security patches

## Development

### Making Changes

1. Modify the Dockerfile or CloudronManifest.json
2. Test locally with docker-compose
3. Rebuild the package
4. Test on a staging Cloudron instance
5. Deploy to production

### Contributing

Feel free to submit issues or pull requests to improve this package.

## Resources

- [Cloudron Documentation](https://docs.cloudron.io)
- [Cloudron Custom Apps Guide](https://docs.cloudron.io/custom-apps/)
- [Shopify MCP Documentation](https://github.com/shopify/dev-mcp)
- [MCP Protocol Specification](https://modelcontextprotocol.io)

## License

This Cloudron package is provided as-is for use with the Shopify MCP server.

## Support

- Cloudron Forums: https://forum.cloudron.io
- GitHub Issues: [Your repository URL]
- Email: support@example.com