// Top pe import karo
const ImageKit = require('imagekit');

// ImageKit initialize karo
const imagekit = new ImageKit({
  publicKey: 'public_Cam/H6qzsPHNMiXi6XxVWOapqBc=',      // Tumhara public key
  privateKey: 'private_ZVGA+wsSKWA7i0NnXdoVdG5JtJM=',    // Tumhara private key
  urlEndpoint: 'https://ik.imagekit.io/5ey3dxl6g'
});

// Auth endpoint add karo (existing routes ke saath)
app.get('/api/imagekit-auth', (req, res) => {
  try {
    const authParams = imagekit.getAuthenticationParameters();
    res.json(authParams);
  } catch (error) {
    res.status(500).json({ error: 'Auth failed' });
  }
});