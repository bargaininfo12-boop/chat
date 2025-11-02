// v1.0-config.dart · 2025-10-26T15:00 IST
// config.dart - ImageKit + Render Configuration
//
// Global configuration constants for the chat app
// Used by MessageRepository, WsClient, CdnUploader, etc.
//
// Place this file at: lib/core/config.dart

class Config {
  // 🔌 WebSocket Configuration (Render)
  static const String WS_ENDPOINT = 'wss://chat-q2sm.onrender.com'; // TODO: Replace with your Render URL

  // ☁️ ImageKit Configuration
  static const String IMAGEKIT_PUBLIC_KEY = 'public_Cam/H6qzsPHNMiXi6XxVWOapqBc=';
  static const String IMAGEKIT_URL_ENDPOINT = 'https://ik.imagekit.io/5ey3dxl6g';
  static const String IMAGEKIT_AUTH_ENDPOINT = 'https://chat-q2sm.onrender.com/api/imagekit-auth';

  // 📤 Upload Configuration
  static const int MAX_UPLOAD_SIZE_MB = 10;
  static const int MAX_UPLOAD_RETRIES = 3;
  static const List<String> SUPPORTED_IMAGE_FORMATS = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'];
  static const List<String> SUPPORTED_VIDEO_FORMATS = ['mp4', 'mov', 'avi', 'mkv'];

  // 🧠 Behavior Flags
  static const bool ENABLE_AUTO_RECONNECT = true;
  static const bool ENABLE_FIREBASE_PUSH = true;
  static const bool ENABLE_IMAGE_COMPRESSION = true;
  static const int IMAGE_COMPRESSION_QUALITY = 85;

  // 🗄️ Local Cache / Database
  static const String LOCAL_DB_NAME = 'chat_local.db';
  static const int LOCAL_DB_VERSION = 3;
  static const int MAX_CACHED_MESSAGES = 500;

  // 🔐 Security / Logging
  static const bool ENABLE_LOGGING = true;
  static const bool ENABLE_FILE_COMPRESSION = true;

  // ⏱️ Timeout & Retry Settings
  static const Duration WS_HEARTBEAT_INTERVAL = Duration(seconds: 30);
  static const Duration WS_HANDSHAKE_TIMEOUT = Duration(seconds: 10);
  static const Duration UPLOAD_RETRY_BASE_DELAY = Duration(milliseconds: 500);
  static const Duration UPLOAD_MAX_RETRY_DELAY = Duration(seconds: 10);
  static const Duration MESSAGE_SEND_TIMEOUT = Duration(seconds: 30);

  // 🎨 UI Configuration
  static const int THUMBNAIL_SIZE = 300;
  static const int MAX_MESSAGE_LENGTH = 5000;
  static const Duration TYPING_INDICATOR_TIMEOUT = Duration(seconds: 3);

  // 🌐 API Endpoints (Optional)
  static const String? HTTP_FALLBACK_ENDPOINT = null;

  // 📊 Analytics & Monitoring
  static const bool ENABLE_ANALYTICS = false;
  static const bool ENABLE_CRASH_REPORTING = false;

  // 🔧 Development Settings
  static const bool USE_MOCK_DATA = false;
  static const bool ENABLE_NETWORK_INSPECTOR = false;

  // 💡 Helper Methods
  static bool isFileSizeValid(int sizeInBytes) {
    return sizeInBytes <= (MAX_UPLOAD_SIZE_MB * 1024 * 1024);
  }

  static bool isImageFormatSupported(String extension) {
    return SUPPORTED_IMAGE_FORMATS.contains(extension.toLowerCase());
  }

  static bool isVideoFormatSupported(String extension) {
    return SUPPORTED_VIDEO_FORMATS.contains(extension.toLowerCase());
  }

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

  static String getThumbnailUrl(String filePath) {
    return getOptimizedImageUrl(
      filePath,
      width: THUMBNAIL_SIZE,
      height: THUMBNAIL_SIZE,
      format: 'webp',
      quality: 80,
    );
  }

  static String getBlurPlaceholderUrl(String filePath) {
    return '$IMAGEKIT_URL_ENDPOINT/tr:bl-10,q-10$filePath';
  }
}
