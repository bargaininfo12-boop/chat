// File: lib/chat/utils/download_status.dart
// Version: v1.0.0 — centralized normalization for download status strings
// Output statuses (canonical): 'idle' | 'downloading' | 'completed' | 'failed'

library download_status;

/// Utility to normalize and work with download status strings across UI layers.
class DownloadStatus {
  static const String idle = 'idle';
  static const String downloading = 'downloading';
  static const String completed = 'completed';
  static const String failed = 'failed';

  /// Normalizes various incoming values to one of the canonical statuses.
  /// Accepts common variants like 'complete', 'error', 'progress', etc.
  static String normalize(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return idle;

    switch (v) {
      case idle:
        return idle;
      case downloading:
      case 'progress':
      case 'in_progress':
      case 'in-progress':
        return downloading;
      case completed:
      case 'complete':
      case 'done':
        return completed;
      case failed:
      case 'error':
      case 'errored':
      case 'failure':
        return failed;
      default:
        return idle;
    }
  }

  /// Returns true when the status indicates an active/ongoing download.
  static bool isActive(String? raw) => normalize(raw) == downloading;

  /// Returns true when the status indicates a terminal end-state.
  static bool isTerminal(String? raw) {
    final n = normalize(raw);
    return n == completed || n == failed;
  }

  /// Optional: short human labels; keep UI phrasing consistent.
  static String shortLabel(String? raw) {
    switch (normalize(raw)) {
      case idle:
        return 'Tap to download';
      case downloading:
        return 'Downloading…';
      case completed:
        return 'Downloaded';
      case failed:
        return 'Retry download';
      default:
        return 'Tap to download';
    }
  }
}
