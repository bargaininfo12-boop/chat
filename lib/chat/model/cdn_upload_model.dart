// v0.3-cdn_upload_model · 2025-10-25T05:23 IST
// cdn_upload_model.dart
//
// Single source for CDN upload response model used by cdn_uploader and message repo.

class CdnUploadModel {
  final String uploadUrl;   // presigned URL to PUT/POST
  final String cdnUrl;      // final public cdn URL to use in messages
  final String? thumbUrl;   // optional thumbnail/transform URL
  final String uploadMethod; // 'PUT' or 'POST'

  CdnUploadModel({
    required this.uploadUrl,
    required this.cdnUrl,
    this.thumbUrl,
    this.uploadMethod = 'PUT',
  });

  factory CdnUploadModel.fromJson(Map<String, dynamic> json) {
    return CdnUploadModel(
      uploadUrl: json['uploadUrl'] as String,
      cdnUrl: json['cdnUrl'] as String,
      thumbUrl: json['thumbUrl'] as String?,
      uploadMethod: json['uploadMethod'] as String? ?? 'PUT',
    );
  }

  Map<String, dynamic> toJson() => {
    'uploadUrl': uploadUrl,
    'cdnUrl': cdnUrl,
    'thumbUrl': thumbUrl,
    'uploadMethod': uploadMethod,
  };
}
