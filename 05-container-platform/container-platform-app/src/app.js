const express = require("express");
const os = require("os");

const app = express();
const port = process.env.PORT || 8080;
const appVersion = process.env.APP_VERSION || "1.0.0";
const environment = process.env.NODE_ENV || "development";

const status = "Running";
const currentTime = new Date().toLocaleString("en-US", {
  dateStyle: "long",
  timeStyle: "medium",
  timeZone: "UTC"
});
const uptime = `${Math.floor(process.uptime())} seconds`;
const nodeVersion = process.version;
const platform = `${process.platform} ${process.arch}`;

app.use(express.json());

app.get("/", (req, res) => {
  res.status(200).send(`
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Container Platform App</title>

        <style>
          * {
            box-sizing: border-box;
          }

          body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(135deg, #111827, #1f2937);
            color: #f9fafb;
          }

          .container {
            width: 100%;
            max-width: 900px;
            padding: 40px;
            border: 1px solid #374151;
            border-radius: 16px;
            background: rgba(17, 24, 39, 0.92);
            box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
          }

          h1 {
            margin-top: 0;
            margin-bottom: 12px;
            font-size: 2.4rem;
          }

          .subtitle {
            margin-bottom: 32px;
            color: #d1d5db;
            line-height: 1.6;
          }

          .metadata {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 32px;
          }

          .card {
            padding: 18px;
            border: 1px solid #374151;
            border-radius: 10px;
            background: #1f2937;
          }

          .label {
            display: block;
            margin-bottom: 8px;
            color: #9ca3af;
            font-size: 0.85rem;
            text-transform: uppercase;
          }

          .value {
            font-weight: bold;
          }

          .endpoints {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 12px;
          }

          a {
            display: block;
            padding: 14px 16px;
            border: 1px solid #4b5563;
            border-radius: 8px;
            color: #f9fafb;
            text-decoration: none;
            background: #111827;
          }

          a:hover {
            background: #374151;
          }

          footer {
            margin-top: 32px;
            color: #9ca3af;
            font-size: 0.9rem;
          }
        </style>
      </head>

      <body>
        <main class="container">
          <h1>Container Platform App</h1>

          <p class="subtitle">
            A lightweight Node.js application created for Docker, Amazon ECR,
            Amazon ECS, Amazon EKS, CI/CD, GitOps, and monitoring labs.
          </p>

          <section class="metadata">
            <div class="card">
              <span class="label">Status</span>
              <span class="value">🟢 ${status}</span>
            </div>

            <div class="card">
              <span class="label">Uptime</span>
              <span class="value">${uptime}</span>
            </div>

            <div class="card">
              <span class="label">Current Time</span>
              <span class="value">${currentTime}</span>
            </div>

            <div class="card">
              <span class="label">Node Version</span>
              <span class="value">${nodeVersion}</span>
            </div>

            <div class="card">
              <span class="label">Platform</span>
              <span class="value">${platform}</span>
            </div>
          </section>

          <h2>API Endpoints</h2>

          <section class="endpoints">
            <a href="/health">/health</a>
            <a href="/version">/version</a>
            <a href="/hostname">/hostname</a>
            <a href="/environment">/environment</a>
            <a href="/info">/info</a>
          </section>

          <footer>
            <strong>DevOps Homelab</strong><br>
            Node.js • Express • Docker • AWS • Kubernetes
          </footer>
        </main>
      </body>
    </html>
  `);
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

app.get("/version", (req, res) => {
  res.status(200).json({
    version: appVersion,
  });
});

app.get("/hostname", (req, res) => {
  res.status(200).json({
    hostname: os.hostname(),
  });
});

app.get("/environment", (req, res) => {
  res.status(200).json({
    environment,
    port,
  });
});

app.get("/info", (req, res) => {
  res.status(200).json({
    application: "Container Platform App",
    nodeVersion: process.version,
    platform: process.platform,
    architecture: process.arch,
    hostname: os.hostname(),
    uptimeSeconds: Math.floor(process.uptime()),
  });
});

app.use((req, res) => {
  res.status(404).json({
    error: "Route not found",
    path: req.originalUrl,
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Container Platform App running on port ${port}`);
});