const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const ImageKit = require('imagekit');

// Express app initialize
const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ImageKit initialize
const imagekit = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT
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
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
