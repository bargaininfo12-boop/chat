// ============================================
// 📱 Backend Server - ImageKit + WebSocket
// ============================================

require('dotenv').config();

const express = require('express');
const { WebSocketServer } = require('ws');
const { createServer } = require('http');
const ImageKit = require('imagekit');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const httpServer = createServer(app);

// ✅ WebSocket Server (Flutter ke liye)
const wss = new WebSocketServer({ server: httpServer });

// ============================================
// ✅ ImageKit Configuration
// ============================================

console.log('📋 Checking ImageKit Credentials:');
console.log('  IMAGEKIT_PUBLIC_KEY:', process.env.IMAGEKIT_PUBLIC_KEY ? '✅' : '❌');
console.log('  IMAGEKIT_PRIVATE_KEY:', process.env.IMAGEKIT_PRIVATE_KEY ? '✅' : '❌');
console.log('  IMAGEKIT_URL_ENDPOINT:', process.env.IMAGEKIT_URL_ENDPOINT ? '✅' : '❌');

const imagekit = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT
});

// ============================================
// ✅ REST API Routes
// ============================================

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: '✅ Server chalti hai' });
});

// ImageKit Auth Endpoint
app.get('/api/imagekit-auth', (req, res) => {
  try {
    console.log('🔓 ImageKit Auth Request');

    const authParams = imagekit.getAuthenticationParameters();
    if (!authParams) throw new Error('Auth parameters generate nahi ho sake');

    // ✅ Declare only once
    const folderPath = 'bargain/chat/uploads';
    const fileName = `${Date.now()}_${Math.floor(Math.random() * 1000)}.jpg`;
    const fullKey = `${folderPath}/${fileName}`;

    const response = {
      publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
      token: authParams.token,
      signature: authParams.signature,
      expire: authParams.expire,
      key: fullKey,
      fileName: fileName,
      folder: folderPath
    };

    console.log('📦 Upload key:', fullKey);
    res.status(200).json(response);
  } catch (error) {
    console.error('❌ Auth Failed:', error.message);
    res.status(500).json({ error: 'Auth failed', message: error.message });
  }
});

// Debug endpoint
app.get('/debug/credentials', (req, res) => {
  res.json({
    IMAGEKIT_PUBLIC_KEY_SET: !!process.env.IMAGEKIT_PUBLIC_KEY,
    IMAGEKIT_PRIVATE_KEY_SET: !!process.env.IMAGEKIT_PRIVATE_KEY,
    IMAGEKIT_URL_ENDPOINT_SET: !!process.env.IMAGEKIT_URL_ENDPOINT,
    IMAGEKIT_PUBLIC_KEY_LENGTH: process.env.IMAGEKIT_PUBLIC_KEY?.length || 0,
    IMAGEKIT_PRIVATE_KEY_LENGTH: process.env.IMAGEKIT_PRIVATE_KEY?.length || 0,
  });
});

// ============================================
// ✅ WebSocket Connection Handler
// ============================================

wss.on('connection', (ws) => {
  console.log('✅ Client connected');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log('📨 Event received:', data.event);

      if (data.event === 'ping') {
        ws.send(JSON.stringify({ event: 'pong', data: {} }));
        return;
      }

      if (data.event === 'message.send') {
        const serverId = 'srv_' + Date.now();
        console.log('📤 Message sending:', data.data?.tempId);

        const ackResponse = {
          event: 'message.ack',
          data: {
            tempId: data.data?.tempId,
            serverId: serverId,
            status: 'sent'
          }
        };
        ws.send(JSON.stringify(ackResponse));
        console.log('✅ ACK sent');

        const broadcastMsg = {
          event: 'message.new',
          data: {
            ...data.data,
            serverId: serverId,
            id: serverId,
            createdAt: new Date().toISOString(),
            timestamp: Date.now()
          }
        };

        console.log('📢 Broadcasting to', wss.clients.size, 'clients');
        wss.clients.forEach((client) => {
          if (client.readyState === 1) {
            client.send(JSON.stringify(broadcastMsg));
          }
        });
        return;
      }

      if (data.event === 'presence.update') {
        console.log('👤 Presence update:', data.data?.status);

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

      console.log('🔹 Unknown event:', data.event);
      wss.clients.forEach((client) => {
        if (client.readyState === 1) {
          client.send(message);
        }
      });

    } catch (e) {
      console.error('❌ Message parsing error:', e.message);
    }
  });

  ws.on('close', () => {
    console.log('❌ Client disconnected');
  });

  ws.on('error', (error) => {
    console.error('⚠️ WebSocket error:', error.message);
  });
});

// ============================================
// ✅ Server Start
// ============================================

const PORT = process.env.PORT || 3001;

httpServer.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════╗
║   ✅ Backend Server Started            ║
╠════════════════════════════════════════╣
║   Port: ${PORT}                              ║
║   Health: http://localhost:${PORT}/health   ║
║   Auth: http://localhost:${PORT}/api/imagekit-auth ║
║   WebSocket: wss://localhost:${PORT}        ║
╚════════════════════════════════════════╝
  `);

  console.log('\n📋 Endpoints:');
  console.log('  ✅ GET /health');
  console.log('  ✅ GET /api/imagekit-auth');
  console.log('  ✅ GET /debug/credentials');
  console.log('  ✅ WebSocket connection');
});

// ============================================
// Error Handler
// ============================================

app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});
