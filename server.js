#!/usr/bin/env node

const { spawn } = require('child_process');
const http = require('http');
const process = require('process');

const PORT = process.env.PORT || 8080;
const AUTH_TYPE = process.env.AUTH_TYPE;
const AUTH_TOKEN = process.env.AUTH_TOKEN;
const AUTH_HEADER_NAME = process.env.AUTH_HEADER_NAME || 'Authorization';

let mcpProcess = null;
let isHealthy = false;
let mcpStdin = null;
let mcpStdout = null;

// Store pending requests by their JSON-RPC ID
const pendingRequests = new Map();
let requestId = 0;

function startMCPServer() {
  const args = ['@shopify/dev-mcp@latest'];
  
  if (AUTH_TYPE && AUTH_TOKEN) {
    args.push('--auth-type', AUTH_TYPE);
    args.push('--auth-token', AUTH_TOKEN);
    if (AUTH_HEADER_NAME !== 'Authorization') {
      args.push('--auth-header', AUTH_HEADER_NAME);
    }
  }

  console.log('Starting MCP server with args:', args);
  
  mcpProcess = spawn('npx', ['-y', ...args], {
    stdio: ['pipe', 'pipe', 'inherit'],
    env: {
      ...process.env,
      NPM_CONFIG_CACHE: '/tmp/.npm'
    }
  });

  mcpStdin = mcpProcess.stdin;
  mcpStdout = mcpProcess.stdout;

  // Buffer for incomplete JSON messages
  let messageBuffer = '';

  mcpStdout.on('data', (data) => {
    messageBuffer += data.toString();
    
    // Process complete JSON-RPC messages
    const lines = messageBuffer.split('\n');
    messageBuffer = lines.pop() || ''; // Keep the incomplete line
    
    for (const line of lines) {
      if (line.trim()) {
        try {
          const response = JSON.parse(line);
          console.log('Received from MCP server:', response);
          
          // Find and resolve the corresponding pending request
          if (response.id !== undefined && pendingRequests.has(response.id)) {
            const { resolve } = pendingRequests.get(response.id);
            pendingRequests.delete(response.id);
            resolve(response);
          }
        } catch (error) {
          console.error('Failed to parse JSON response from MCP server:', error, 'Raw:', line);
        }
      }
    }
  });

  mcpProcess.on('spawn', () => {
    console.log('MCP server started');
    isHealthy = true;
  });

  mcpProcess.on('error', (error) => {
    console.error('MCP server error:', error);
    isHealthy = false;
  });

  mcpProcess.on('exit', (code, signal) => {
    console.log(`MCP server exited with code ${code}, signal ${signal}`);
    isHealthy = false;
    mcpStdin = null;
    mcpStdout = null;
    
    // Reject all pending requests
    for (const [, { reject }] of pendingRequests.entries()) {
      reject(new Error('MCP server exited'));
    }
    pendingRequests.clear();
    
    // Restart the server if it wasn't killed intentionally
    if (code !== 0 && signal !== 'SIGTERM' && signal !== 'SIGINT') {
      console.log('Restarting MCP server...');
      setTimeout(startMCPServer, 5000);
    }
  });
}

// Function to send JSON-RPC request to MCP server
function sendToMCPServer(request) {
  return new Promise((resolve, reject) => {
    if (!mcpStdin || !isHealthy) {
      reject(new Error('MCP server not available'));
      return;
    }

    // Ensure request has an ID for tracking
    if (request.id === undefined) {
      request.id = ++requestId;
    }

    console.log('Sending to MCP server:', request);
    
    // Store the promise resolvers
    pendingRequests.set(request.id, { resolve, reject });
    
    // Set a timeout for the request
    setTimeout(() => {
      if (pendingRequests.has(request.id)) {
        pendingRequests.delete(request.id);
        reject(new Error('Request timeout'));
      }
    }, 30000); // 30 second timeout
    
    // Send the request to the MCP server
    try {
      mcpStdin.write(JSON.stringify(request) + '\n');
    } catch (error) {
      pendingRequests.delete(request.id);
      reject(error);
    }
  });
}

// Authentication middleware
function authenticate(req) {
  if (!AUTH_TYPE || !AUTH_TOKEN) {
    return true; // No authentication required
  }

  const authHeader = req.headers[AUTH_HEADER_NAME.toLowerCase()];
  
  if (!authHeader) {
    return false;
  }

  if (AUTH_TYPE === 'header') {
    return authHeader === AUTH_TOKEN;
  } else if (AUTH_TYPE === 'oauth2bearer') {
    return authHeader === `Bearer ${AUTH_TOKEN}` || authHeader === AUTH_TOKEN;
  }
  
  return false;
}

// Parse JSON body
function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

// Create HTTP server
const server = http.createServer(async (req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, ' + AUTH_HEADER_NAME);

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Health check endpoint
  if (req.url === '/health') {
    res.writeHead(isHealthy ? 200 : 503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ 
      status: isHealthy ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      service: 'shopify-mcp-server'
    }));
    return;
  }

  // MCP endpoint
  if (req.url === '/mcp' || req.url === '/') {
    // Check authentication
    if (!authenticate(req)) {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        jsonrpc: '2.0',
        error: { 
          code: -32600, 
          message: 'Authentication required' 
        }
      }));
      return;
    }

    if (req.method === 'GET') {
      // Return server info for GET requests
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        name: 'Shopify MCP Server',
        version: '1.0.0',
        description: 'Shopify Development MCP Server for AI model integration',
        transport: 'http',
        protocols: ['mcp'],
        status: isHealthy ? 'healthy' : 'unhealthy'
      }));
      return;
    }

    if (req.method === 'POST') {
      if (!isHealthy) {
        res.writeHead(503, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          jsonrpc: '2.0',
          error: {
            code: -32000,
            message: 'MCP server not available'
          }
        }));
        return;
      }

      try {
        const body = await parseBody(req);
        console.log('Received HTTP request:', body);
        
        // Validate JSON-RPC format
        if (!body.jsonrpc || body.jsonrpc !== '2.0') {
          res.writeHead(400, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            jsonrpc: '2.0',
            error: {
              code: -32600,
              message: 'Invalid Request - missing or invalid jsonrpc field'
            },
            id: body.id || null
          }));
          return;
        }

        // Forward the request to the MCP server
        const response = await sendToMCPServer(body);
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(response));
        
      } catch (error) {
        console.error('Error processing request:', error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          jsonrpc: '2.0',
          error: {
            code: -32603,
            message: 'Internal error',
            data: error.message
          },
          id: null
        }));
      }
      return;
    }
  }

  // 404 for other endpoints
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

// Graceful shutdown
function shutdown() {
  console.log('Shutting down...');
  server.close(() => {
    if (mcpProcess) {
      mcpProcess.kill('SIGTERM');
    }
    process.exit(0);
  });
}

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start the MCP server
startMCPServer();

// Start the HTTP server
server.listen(PORT, () => {
  console.log(`MCP HTTP server running on port ${PORT}`);
  console.log(`MCP endpoint available at: http://localhost:${PORT}/mcp`);
  console.log(`Health check available at: http://localhost:${PORT}/health`);
});