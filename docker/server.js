const http = require('http');
const fs = require('fs');
const path = require('path');

// Get environment variables
const PORT = process.env.PORT || 8080;
const PROJECT = process.env.PROJECT || 'cloud-portfolio';
const ENVIRONMENT = process.env.ENVIRONMENT || 'dev';
const CONTAINER_ID = process.env.HOSTNAME || 'unknown';

// Simple request counter for demo
let requestCount = 0;
const startTime = new Date();

// Create HTTP server
const server = http.createServer((req, res) => {
  requestCount++;
  const timestamp = new Date().toISOString();

  console.log(`${timestamp} - ${req.method} ${req.url} - Request #${requestCount}`);

  // Health check endpoint
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'healthy',
      timestamp: timestamp,
      uptime: Math.floor((Date.now() - startTime) / 1000),
      requestCount: requestCount
    }));
    return;
  }

  // Metrics endpoint
  if (req.url === '/metrics') {
    const uptime = Math.floor((Date.now() - startTime) / 1000);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      project: PROJECT,
      environment: ENVIRONMENT,
      containerId: CONTAINER_ID,
      requestCount: requestCount,
      uptime: uptime,
      memory: process.memoryUsage(),
      timestamp: timestamp
    }));
    return;
  }

  // Main page
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cloud Portfolio - Containerized App</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 20px;
    }

    .container {
      text-align: center;
      padding: 60px 40px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 20px;
      backdrop-filter: blur(10px);
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
      border: 1px solid rgba(255, 255, 255, 0.18);
      max-width: 800px;
      width: 100%;
    }

    h1 {
      font-size: 3.5em;
      margin-bottom: 20px;
      text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
    }

    .subtitle {
      font-size: 1.3em;
      margin-bottom: 40px;
      opacity: 0.9;
    }

    .badge-container {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      gap: 15px;
      margin: 30px 0;
    }

    .badge {
      display: inline-block;
      padding: 12px 24px;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 25px;
      font-size: 0.95em;
      font-weight: 500;
      backdrop-filter: blur(5px);
      border: 1px solid rgba(255, 255, 255, 0.3);
    }

    .stats {
      margin-top: 40px;
      padding-top: 30px;
      border-top: 2px solid rgba(255, 255, 255, 0.3);
    }

    .stat-item {
      display: inline-block;
      margin: 10px 20px;
      font-size: 0.9em;
    }

    .stat-value {
      font-size: 2em;
      font-weight: bold;
      display: block;
      margin-bottom: 5px;
    }

    .emoji {
      font-size: 1.5em;
      margin: 0 5px;
    }

    hr {
      border: none;
      border-top: 2px solid rgba(255, 255, 255, 0.3);
      margin: 30px 0;
    }

    .complete-message {
      font-size: 1.5em;
      margin-top: 20px;
      font-weight: 600;
    }

    .tech-stack {
      margin-top: 30px;
      font-size: 0.85em;
      opacity: 0.8;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1><span class="emoji">🐳</span> Containerized Application</h1>
    <p class="subtitle">Running on AWS ECS Fargate</p>

    <div class="badge-container">
      <div class="badge">Project: ${PROJECT}</div>
      <div class="badge">Environment: ${ENVIRONMENT}</div>
      <div class="badge">Container: ${CONTAINER_ID.substring(0, 12)}</div>
      <div class="badge">Platform: <span class="emoji">☁️</span> Fargate Serverless</div>
    </div>

    <div class="stats">
      <div class="stat-item">
        <span class="stat-value">${requestCount}</span>
        <span>Requests Served</span>
      </div>
      <div class="stat-item">
        <span class="stat-value">${Math.floor((Date.now() - startTime) / 1000)}s</span>
        <span>Uptime</span>
      </div>
    </div>

    <hr>

    <div class="complete-message">
      <span class="emoji">🎉</span> Week 7 Complete! <span class="emoji">🎉</span>
    </div>

    <div class="tech-stack">
      <p><strong>Tech Stack:</strong> Node.js · Docker · ECR · ECS Fargate · X-Ray · CloudWatch</p>
      <p><strong>Features:</strong> Auto-scaling · Health Checks · Service Discovery · Distributed Tracing</p>
    </div>
  </div>

  <script>
    // Auto-refresh stats every 5 seconds
    setInterval(() => {
      fetch('/metrics')
        .then(r => r.json())
        .then(data => {
          console.log('Container Metrics:', data);
        })
        .catch(e => console.error('Metrics error:', e));
    }, 5000);
  </script>
</body>
</html>
  `);
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Project: ${PROJECT}, Environment: ${ENVIRONMENT}`);
  console.log(`Container: ${CONTAINER_ID}`);
  console.log(`Started: ${startTime.toISOString()}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
