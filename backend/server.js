// backend/server.js
const express = require('express');
const { WebSocketServer } = require('ws');
const { createServer } = require('http');
const ImageKit = require('imagekit');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const httpServer = createServer(app);

// WebSocket Server (for Flutter)
const wss = new WebSocketServer({ server: httpServer });

// ImageKit
const imagekit = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT
});

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/imagekit-auth', (req, res) => {
  try {
    const authParams = imagekit.getAuthenticationParameters();
    res.json(authParams);
  } catch (error) {
    res.status(500).json({ error: 'Auth failed' });
  }
});

// WebSocket Connection
wss.on('connection', (ws) => {
  console.log('✅ Client connected');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('📨 Received event:', data.event);

      // Handle ping/pong
      if (data.event === 'ping') {
        ws.send(JSON.stringify({ event: 'pong', data: {} }));
        return;
      }

      // Handle message.send
      if (data.event === 'message.send') {
        const response = {
          event: 'message.ack',
          data: {
            tempId: data.data?.tempId,
            serverId: 'srv_' + Date.now(),
            status: 'sent'
          }
        };
        ws.send(JSON.stringify(response));

        // Broadcast new message to all clients
        const broadcastMsg = {
          event: 'message.new',
          data: {
            ...data.data,
            serverId: 'srv_' + Date.now(),
            createdAt: new Date().toISOString()
          }
        };

        wss.clients.forEach((client) => {
          if (client.readyState === 1) {
            client.send(JSON.stringify(broadcastMsg));
          }
        });
        return;
      }

      // Handle presence.update
      if (data.event === 'presence.update') {
        const presenceMsg = {
          event: 'presence.update',
          data: data.data
        };

        wss.clients.forEach((client) => {
          if (client.readyState === 1) {
            client.send(JSON.stringify(presenceMsg));
          }
        });
        return;
      }

      // Broadcast unknown events
      wss.clients.forEach((client) => {
        if (client.readyState === 1) {
          client.send(message);
        }
      });
    } catch (e) {
      console.error('❌ Error parsing message:', e.message);
    }
  });

  ws.on('close', () => {
    console.log('❌ Client disconnected');
  });

  ws.on('error', (error) => {
    console.error('⚠️ WebSocket error:', error.message);
  });
});

const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`📡 WebSocket ready at wss://your-domain.com`);
});