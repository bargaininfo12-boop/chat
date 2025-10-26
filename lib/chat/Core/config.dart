  // v1.0-config.dart · 2025-10-26T15:00 IST
  // config.dart - ImageKit + Render Configuration
  //
  // Global configuration constants for the chat app
  // Used by MessageRepository, WsClient, CdnUploader, etc.
  //
  // Place this file at: lib/core/config.dart

  class Config {
    // ===========================
    // 🔌 WebSocket Configuration (Render)
    // ===========================

    /// Render WebSocket endpoint
    /// TODO: Replace with YOUR Render URL after deployment
    /// Example: 'wss://chat-websocket-abc123.onrender.com'
    static const String WS_ENDPOINT =
        'wss://chat-q2sm.onrender.com';   // change karna hai baad me

    // ===========================
    // ☁️ ImageKit Configuration
    // ===========================

    /// ImageKit Public Key (safe to expose in client)
    /// Get from: https://imagekit.io/dashboard → Settings → API Keys
    static const String IMAGEKIT_PUBLIC_KEY =
        'public_Cam/H6qzsPHNMiXi6XxVWOapqBc=';

    /// ImageKit URL Endpoint
    /// Get from: https://imagekit.io/dashboard → Settings → API Keys
    /// Example: 'https://ik.imagekit.io/your_imagekit_id'
    static const String IMAGEKIT_URL_ENDPOINT =
        'https://ik.imagekit.io/5ey3dxl6g';

    /// ImageKit Auth Endpoint (your Render backend)
    /// This will be YOUR_RENDER_URL + /api/imagekit-auth
    /// TODO: Update after Render deployment
    static const String IMAGEKIT_AUTH_ENDPOINT =
        'https://chat-q2sm.onrender.com/api/imagekit-auth';

    // ===========================
    // 📤 Upload Configuration
    // ===========================

    /// Maximum upload size (in MB)
    static const int MAX_UPLOAD_SIZE_MB = 10; // ImageKit free: recommended 10MB

    /// Retry limits for failed uploads
    static const int MAX_UPLOAD_RETRIES = 3;

    /// Supported image formats
    static const List<String> SUPPORTED_IMAGE_FORMATS = [
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'
    ];

    /// Supported video formats
    static const List<String> SUPPORTED_VIDEO_FORMATS = [
      'mp4', 'mov', 'avi', 'mkv'
    ];

    // ===========================
    // 🧠 Behavior Flags
    // ===========================

    /// Enable automatic WebSocket reconnection
    static const bool ENABLE_AUTO_RECONNECT = true;

    /// Enable Firebase Cloud Messaging for push notifications
    static const bool ENABLE_FIREBASE_PUSH = true;

    /// Enable image compression before upload
    static const bool ENABLE_IMAGE_COMPRESSION = true;

    /// Compression quality (0-100)
    static const int IMAGE_COMPRESSION_QUALITY = 85;

    // ===========================
    // 🗄️ Local Cache / Database
    // ===========================

    /// Local SQLite database name
    static const String LOCAL_DB_NAME = 'chat_local.db';

    /// Database version (increment on schema changes)
    static const int LOCAL_DB_VERSION = 3;

    /// Maximum messages to keep in local cache per conversation
    static const int MAX_CACHED_MESSAGES = 500;

    // ===========================
    // 🔐 Security / Logging
    // ===========================

    /// Enable debug logging (disable in production)
    static const bool ENABLE_LOGGING = true;

    /// Enable file compression before upload
    static const bool ENABLE_FILE_COMPRESSION = true;

    // ===========================
    // ⏱️ Timeout & Retry Settings
    // ===========================

    /// WebSocket heartbeat interval (ping/pong)
    static const Duration WS_HEARTBEAT_INTERVAL = Duration(seconds: 30);

    /// WebSocket connection timeout
    static const Duration WS_HANDSHAKE_TIMEOUT = Duration(seconds: 10);

    /// Base delay for upload retry (exponential backoff)
    static const Duration UPLOAD_RETRY_BASE_DELAY = Duration(milliseconds: 500);

    /// Maximum delay between upload retries
    static const Duration UPLOAD_MAX_RETRY_DELAY = Duration(seconds: 10);

    /// Message send timeout
    static const Duration MESSAGE_SEND_TIMEOUT = Duration(seconds: 30);

    // ===========================
    // 🎨 UI Configuration
    // ===========================

    /// Thumbnail size for image messages
    static const int THUMBNAIL_SIZE = 300;

    /// Maximum message length
    static const int MAX_MESSAGE_LENGTH = 5000;

    /// Typing indicator timeout
    static const Duration TYPING_INDICATOR_TIMEOUT = Duration(seconds: 3);

    // ===========================
    // 🌐 API Endpoints (Optional)
    // ===========================

    /// HTTP fallback endpoint (if WebSocket fails)
    /// Optional - leave null if not using HTTP fallback
    static const String? HTTP_FALLBACK_ENDPOINT = null;
    // Example: 'https://your-app-name.onrender.com/api/messages';

    // ===========================
    // 📊 Analytics & Monitoring
    // ===========================

    /// Enable analytics
    static const bool ENABLE_ANALYTICS = false;

    /// Enable crash reporting
    static const bool ENABLE_CRASH_REPORTING = false;

    // ===========================
    // 🔧 Development Settings
    // ===========================

    /// Use mock data in development
    static const bool USE_MOCK_DATA = false;

    /// Enable network inspector
    static const bool ENABLE_NETWORK_INSPECTOR = false;

    // ===========================
    // 💡 Helper Methods
    // ===========================

    /// Check if file size is within limits
    static bool isFileSizeValid(int sizeInBytes) {
      return sizeInBytes <= (MAX_UPLOAD_SIZE_MB * 1024 * 1024);
    }

    /// Check if file format is supported
    static bool isImageFormatSupported(String extension) {
      return SUPPORTED_IMAGE_FORMATS.contains(extension.toLowerCase());
    }

    /// Check if video format is supported
    static bool isVideoFormatSupported(String extension) {
      return SUPPORTED_VIDEO_FORMATS.contains(extension.toLowerCase());
    }

    /// Get ImageKit optimized URL with transformations
    static String getOptimizedImageUrl(
        String filePath, {
          int? width,
          int? height,
          String format = 'webp',
          int quality = 80,
        }) {
      final transformations = <String>[];
      if (width != null) transformations.add('w-$width');
      if (height != null) transformations.add('h-$height');
      transformations.add('f-$format');
      transformations.add('q-$quality');

      final tr = transformations.join(',');
      return '$IMAGEKIT_URL_ENDPOINT/tr:$tr$filePath';
    }

    /// Get ImageKit thumbnail URL
    static String getThumbnailUrl(String filePath) {
      return getOptimizedImageUrl(
        filePath,
        width: THUMBNAIL_SIZE,
        height: THUMBNAIL_SIZE,
        format: 'webp',
        quality: 80,
      );
    }

    /// Get blur placeholder URL for lazy loading
    static String getBlurPlaceholderUrl(String filePath) {
      return '$IMAGEKIT_URL_ENDPOINT/tr:bl-10,q-10$filePath';
    }
  }
