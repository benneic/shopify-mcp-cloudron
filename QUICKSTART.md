# Quick Start Guide - Shopify MCP Server on Cloudron

## 🚀 5-Minute Deployment

### Prerequisites
- A Cloudron server (v7.4.0+)
- Shopify Partner account or store admin access
- Basic command line knowledge

### Step 1: Get Shopify API Credentials

1. Go to your Shopify Admin → Apps → Develop apps
2. Create a new app or use existing one
3. Configure API scopes (minimum required):
   - `read_products`
   - `write_products`
   - `read_orders`
   - `read_customers`
4. Install the app to get your Access Token
5. Note down:
   - API Key
   - API Secret
   - Access Token
   - Store Domain (your-store.myshopify.com)

### Step 2: Prepare the Package

```bash
# Clone or download this package
git clone https://github.com/yourusername/shopify-mcp-cloudron.git
cd shopify-mcp-cloudron

# Make build script executable
chmod +x build.sh

# Build the package
./build.sh
```

### Step 3: Deploy to Cloudron

#### Option A: Using CLI (Recommended)

```bash
# Login to your Cloudron
cloudron login my.cloudron.domain

# Install the app
cloudron install \
  --location mcp.yourdomain.com \
  --image com.shopify.mcp-server@1.0.0.tar.gz
```

#### Option B: Using Web Interface

1. Open Cloudron dashboard
2. Click "App Store" → "Upload"
3. Upload `com.shopify.mcp-server@1.0.0.tar.gz`
4. Choose subdomain (e.g., `mcp`)
5. Click "Install"

### Step 4: Configure the App

1. In Cloudron dashboard, click on your MCP Server app
2. Go to "Configuration" → "Environment"
3. Add these required variables:

```
SHOPIFY_API_KEY=your_api_key
SHOPIFY_API_SECRET=your_api_secret
SHOPIFY_STORE_DOMAIN=your-store.myshopify.com
SHOPIFY_ACCESS_TOKEN=your_access_token
```

4. Click "Save" and wait for restart

### Step 5: Verify Installation

```bash
# Check if server is running
curl https://mcp.yourdomain.com/health

# View logs
cloudron logs --app mcp.yourdomain.com
```

## 🔧 Basic Usage

### Connect from Your Application

```javascript
// Example: Node.js client
const axios = require('axios');

const mcpEndpoint = 'https://mcp.yourdomain.com';

// Example: Fetch products
async function getProducts() {
  const response = await axios.post(`${mcpEndpoint}/rpc`, {
    method: 'products.list',
    params: {
      limit: 10
    }
  });
  return response.data;
}
```

### Using with AI Assistants

Configure your AI assistant to use the MCP endpoint:

```json
{
  "mcp_servers": {
    "shopify": {
      "endpoint": "https://mcp.yourdomain.com",
      "protocol": "mcp"
    }
  }
}
```

## 📋 Common Tasks

### View Logs
```bash
cloudron logs --app mcp.yourdomain.com --tail
```

### Restart App
```bash
cloudron restart --app mcp.yourdomain.com
```

### Update Configuration
1. Dashboard → Your App → Configuration → Environment
2. Modify variables
3. Save (auto-restarts)

### Backup Data
Cloudron automatically backs up your app data. Manual backup:
```bash
cloudron backup create --app mcp.yourdomain.com
```

## 🆘 Troubleshooting

### Server Not Starting?
Check logs for errors:
```bash
cloudron logs --app mcp.yourdomain.com | grep ERROR
```

### Connection Refused?
1. Verify environment variables are set
2. Check Shopify API credentials
3. Ensure firewall allows port 3000

### API Errors?
1. Verify API scopes in Shopify
2. Check Access Token is valid
3. Confirm Store Domain is correct

## 📚 Next Steps

1. **Set up monitoring**: Configure uptime monitoring for your endpoint
2. **Add webhook endpoints**: Configure Shopify webhooks for real-time updates
3. **Customize configuration**: Adjust rate limits and features in environment variables
4. **Integrate with your tools**: Connect the MCP server to your development workflow

## 🔗 Quick Links

- [Full Documentation](README.md)
- [Environment Variables](.env.example)
- [Cloudron Docs](https://docs.cloudron.io)
- [Shopify API Docs](https://shopify.dev/api)

## 💡 Tips

- Always test in a development store first
- Keep your API credentials secure
- Monitor rate limits to avoid throttling
- Use Cloudron's automatic backups
- Enable only the API scopes you need

---

**Need Help?** 
- Cloudron Forum: https://forum.cloudron.io
- Create an issue on GitHub
- Check the [README](README.md) for detailed information