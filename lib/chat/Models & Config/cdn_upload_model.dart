// v0.5-cdn_upload_model · 2025-10-26T19:45 IST
// lib/chat/model/cdn_upload_model.dart
//
// Immutable, typed CDN upload response model.
// Used by: CdnUploader, MessageRepository, WsAckHandler.

class CdnUploadModel {
  /// Presigned URL to which the file should be uploaded (PUT/POST)
  final String uploadUrl;

  /// Final public CDN URL (used in messages)
  final String cdnUrl;

  /// Optional thumbnail / transform URL
  final String? thumbUrl;

  /// HTTP method, usually 'PUT' or 'POST'
  final String uploadMethod;

  const CdnUploadModel({
    required this.uploadUrl,
    required this.cdnUrl,
    this.thumbUrl,
    this.uploadMethod = 'PUT',
  });

  /// Create instance from JSON or Map
  factory CdnUploadModel.fromJson(Map<String, dynamic> json) {
    return CdnUploadModel(
      uploadUrl: json['uploadUrl']?.toString() ?? json['url']?.toString() ?? '',
      cdnUrl: json['cdnUrl']?.toString() ??
          json['cdn_url']?.toString() ??
          json['publicUrl']?.toString() ??
          '',
      thumbUrl: json['thumbUrl']?.toString() ??
          json['thumbnail']?.toString() ??
          json['thumb_url']?.toString(),
      uploadMethod: json['uploadMethod']?.toString().toUpperCase() ?? 'PUT',
    );
  }

  /// Support alternate field naming for safety
  factory CdnUploadModel.fromMap(Map<String, dynamic> map) =>
      CdnUploadModel.fromJson(map);

  /// Convert to plain map
  Map<String, dynamic> toJson() => {
    'uploadUrl': uploadUrl,
    'cdnUrl': cdnUrl,
    'thumbUrl': thumbUrl,
    'uploadMethod': uploadMethod,
  };

  /// Copy with optional field replacement
  CdnUploadModel copyWith({
    String? uploadUrl,
    String? cdnUrl,
    String? thumbUrl,
    String? uploadMethod,
  }) {
    return CdnUploadModel(
      uploadUrl: uploadUrl ?? this.uploadUrl,
      cdnUrl: cdnUrl ?? this.cdnUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      uploadMethod: uploadMethod ?? this.uploadMethod,
    );
  }

  /// Validate required fields
  bool get isValid =>
      uploadUrl.isNotEmpty && cdnUrl.isNotEmpty && uploadMethod.isNotEmpty;

  @override
  String toString() =>
      'CdnUploadModel(method: $uploadMethod, cdnUrl: $cdnUrl, thumb: $thumbUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CdnUploadModel &&
              uploadUrl == other.uploadUrl &&
              cdnUrl == other.cdnUrl &&
              thumbUrl == other.thumbUrl &&
              uploadMethod == other.uploadMethod;

  @override
  int get hashCode =>
      Object.hash(uploadUrl, cdnUrl, thumbUrl, uploadMethod);
}
