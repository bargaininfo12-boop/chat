// File: lib/chat/utils/network_manager.dart

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Network state management and error recovery system
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  static NetworkManager get instance => _instance;
  NetworkManager._internal();

  bool _isOnline = true;
  bool _isInitialized = false; // ✅ To prevent multiple initializations
  Timer? _connectivityTimer;   // ✅ Timer for periodic checks

  final StreamController<bool> _networkController = StreamController<bool>.broadcast();

  final List<VoidCallback> _onReconnectCallbacks = [];
  final List<VoidCallback> _onDisconnectCallbacks = [];

  Stream<bool> get networkStream => _networkController.stream;
  bool get isOnline => _isOnline;

  // ✅ ================== नया मेथड यहाँ जोड़ा गया है ==================
  /// Initializes the network manager and starts periodic connectivity checks.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint("⏭️ NetworkManager: Already initialized.");
      return;
    }
    debugPrint("🚀 NetworkManager: Initializing...");
    await checkConnectivity(); // Perform an initial check right away

    // Set up a timer to check connectivity periodically
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkConnectivity();
    });

    _isInitialized = true;
    debugPrint("✅ NetworkManager: Initialized and monitoring network status.");
  }
  // =================================================================

  /// Update network status and notify listeners
  void updateNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _networkController.add(isOnline);

      if (isOnline) {
        debugPrint("✅ Network reconnected");
        _triggerReconnectCallbacks();
      } else {
        debugPrint("📵 Network disconnected");
        _triggerDisconnectCallbacks();
      }
    }
  }

  /// Add callback for network reconnection
  void addReconnectCallback(VoidCallback callback) {
    _onReconnectCallbacks.add(callback);
  }

  /// Add callback for network disconnection
  void addDisconnectCallback(VoidCallback callback) {
    _onDisconnectCallbacks.add(callback);
  }

  void removeReconnectCallback(VoidCallback callback) {
    _onReconnectCallbacks.remove(callback);
  }

  void removeDisconnectCallback(VoidCallback callback) {
    _onDisconnectCallbacks.remove(callback);
  }

  void _triggerReconnectCallbacks() {
    for (final callback in _onReconnectCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint("Error in reconnect callback: $e");
      }
    }
  }

  void _triggerDisconnectCallbacks() {
    for (final callback in _onDisconnectCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint("Error in disconnect callback: $e");
      }
    }
  }

  /// Manually check network connectivity by looking up a reliable host.
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      updateNetworkStatus(isConnected);
      return isConnected;
    } on SocketException catch (_) {
      updateNetworkStatus(false);
      return false;
    }
  }

  /// Dispose resources
  /// Dispose resources
  Future<void> dispose() async {
    _connectivityTimer?.cancel(); // ✅ Cancel periodic checks
    await _networkController.close(); // ✅ Close stream safely
    _onReconnectCallbacks.clear();
    _onDisconnectCallbacks.clear();
    _isInitialized = false;
    debugPrint("🧹 NetworkManager: Disposed.");
  }

}

/// Error recovery manager with retry logic
class ErrorRecoveryManager {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);

  /// Retry operation with exponential backoff
  static Future<T?> withRetry<T>(
      Future<T?> Function() operation,
      String operationName, {
        int? customMaxRetries,
        Duration? customBaseDelay,
        bool Function(dynamic error)? shouldRetry,
      }) async {
    final retries = customMaxRetries ?? maxRetries;
    final delay = customBaseDelay ?? baseDelay;

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        debugPrint("$operationName attempt $attempt failed: $e");

        if (shouldRetry != null && !shouldRetry(e)) {
          debugPrint("$operationName failed with non-retryable error: $e");
          rethrow;
        }

        if (attempt == retries) {
          debugPrint("$operationName failed after $retries attempts");
          rethrow;
        }
      }

      final delayDuration = Duration(milliseconds: delay.inMilliseconds * attempt);
      await Future.delayed(delayDuration);
    }
    return null; // Should not be reached
  }

  /// Check if an error is typically retryable
  static bool isRetryableError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is FirebaseException) {
      return [
        'unavailable',
        'deadline-exceeded',
        'internal',
        'data-loss',
        'resource-exhausted'
      ].contains(error.code);
    }
    return false;
  }

  /// Execute an operation with a network check and automatic retries for common errors
  static Future<T?> withNetworkCheck<T>(
      Future<T?> Function() operation,
      String operationName,
      ) async {
    if (!NetworkManager.instance.isOnline) {
      debugPrint("$operationName skipped - network offline");
      return null;
    }

    return await withRetry(
      operation,
      operationName,
      shouldRetry: isRetryableError,
    );
  }
}
