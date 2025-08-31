FROM cloudron/base:4.2.0@sha256:46da2fffb36353ef714f97ae8e962bd2c212ca091108d768ba473078319a47f4

RUN mkdir -p /app/code /app/data /run/shopify-mcp
WORKDIR /app/code

# Install Node.js 18 (Cloudron base image has Node 16)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create package.json for the app
COPY <<EOF /app/code/package.json
{
  "name": "shopify-mcp-server",
  "version": "1.0.0",
  "description": "Shopify MCP Server for Cloudron",
  "main": "start.sh",
  "scripts": {
    "start": "node start.js"
  },
  "dependencies": {}
}
EOF

# Install global packages
RUN npm install -g @shopify/dev-mcp@latest @latitude-data/supergateway && \
    npm cache clean --force

# Create health check script
COPY <<'EOF' /app/code/healthcheck.sh
#!/bin/bash
# Check if the MCP server process is running
if pgrep -f "supergateway" > /dev/null 2>&1; then
    # Try to check if port is listening
    if netstat -tuln | grep -q ":${PORT:-3000}"; then
        exit 0
    fi
fi
exit 1
EOF

# Create Node.js wrapper for better process management
COPY <<'EOF' /app/code/start.js
const { spawn } = require('child_process');
const path = require('path');

// Configuration
const PORT = process.env.PORT || '3000';
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

console.log(`Starting Shopify MCP Server on port ${PORT}`);
console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);

// Log Shopify configuration status
if (process.env.SHOPIFY_API_KEY) {
    console.log('Shopify API Key: Configured');
} else {
    console.warn('Warning: SHOPIFY_API_KEY not set');
}

if (process.env.SHOPIFY_STORE_DOMAIN) {
    console.log(`Shopify Store: ${process.env.SHOPIFY_STORE_DOMAIN}`);
} else {
    console.warn('Warning: SHOPIFY_STORE_DOMAIN not set');
}

// Start the MCP server
const mcp = spawn('npx', [
    '-y',
    '@latitude-data/supergateway',
    '--stdio',
    'npx -y @shopify/dev-mcp@latest',
    '--port',
    PORT
], {
    stdio: 'inherit',
    env: {
        ...process.env,
        npm_config_cache: '/tmp/.npm'
    }
});

// Handle process events
mcp.on('error', (error) => {
    console.error('Failed to start MCP server:', error);
    process.exit(1);
});

mcp.on('exit', (code, signal) => {
    if (signal) {
        console.log(`MCP server terminated by signal ${signal}`);
    } else {
        console.log(`MCP server exited with code ${code}`);
    }
    process.exit(code || 0);
});

// Handle shutdown signals
['SIGTERM', 'SIGINT'].forEach(signal => {
    process.on(signal, () => {
        console.log(`Received ${signal}, shutting down gracefully...`);
        mcp.kill(signal);
    });
});
EOF

# Create main start script
COPY <<'EOF' /app/code/start.sh
#!/bin/bash
set -eu

# Cloudron data directory setup
if [ ! -d "/app/data/config" ]; then
    mkdir -p /app/data/config
fi

# Setup npm cache directory
export npm_config_cache="/tmp/.npm"
mkdir -p "$npm_config_cache"

# Log startup information
echo "================================================"
echo "Shopify MCP Server for Cloudron"
echo "Version: 1.0.0"
echo "Port: ${PORT:-3000}"
echo "Data Directory: /app/data"
echo "================================================"

# Start the Node.js wrapper
exec node /app/code/start.js
EOF

# Make scripts executable
RUN chmod +x /app/code/start.sh /app/code/healthcheck.sh

# Set proper permissions for cloudron user
RUN chown -R cloudron:cloudron /app/code /app/data /run/shopify-mcp

# Cloudron apps run as non-root user (uid 1000)
USER cloudron

# Health check for Docker/Cloudron
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD /app/code/healthcheck.sh || exit 1

# Expose the port
EXPOSE 3000

# Start command
CMD [ "/app/code/start.sh" ]
