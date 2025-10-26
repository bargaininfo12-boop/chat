const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const ImageKit = require('imagekit');

// Express app initialize
const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ImageKit initialize (HARDCODED - testing)
const imagekit = new ImageKit({
  publicKey: 'public_Cam/H6qzsPHNMiXi6XxVWOapqBc=',
  privateKey: 'private_ZVGA+wsSKWA7i0NnXdoVdG5JtJM=',
  urlEndpoint: 'https://ik.imagekit.io/5ey3dxl6g'
});

// Auth endpoint
app.get('/api/imagekit-auth', (req, res) => {
  try {
    const authParams = imagekit.getAuthenticationParameters();
    res.json(authParams);
  } catch (error) {
    res.status(500).json({ error: 'Auth failed' });
  }
});

// Server start
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
