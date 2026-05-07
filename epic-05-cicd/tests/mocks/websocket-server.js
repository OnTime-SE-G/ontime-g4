#!/usr/bin/env node

const http = require('http');
const WebSocket = require('ws');

const PORT = process.env.PORT || 8004;

// Create HTTP server with health endpoint
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }
  res.writeHead(404);
  res.end();
});

// Attach WebSocket server
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
  console.log('[WebSocket] Client connected');
  
  // Send initial message
  ws.send(JSON.stringify({ type: 'connected', message: 'WebSocket connected' }));
  
  // Echo messages back
  ws.on('message', (message) => {
    console.log('[WebSocket] Received:', message);
    ws.send(JSON.stringify({ type: 'echo', data: message }));
  });
  
  ws.on('close', () => {
    console.log('[WebSocket] Client disconnected');
  });
  
  ws.on('error', (error) => {
    console.error('[WebSocket] Error:', error);
  });
});

server.listen(PORT, () => {
  console.log(`WebSocket mock server listening on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down...');
  server.close();
});
