import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';

/// Data Transfer Object for Attachment
///
/// Maps OpenProject API response to domain entity
class AttachmentModel {
  final int? id;
  final String fileName;
  final int fileSize;
  final String contentType;
  final String? downloadUrl;
  final String? description;
  final DateTime? createdAt;
  final String? localFilePath;

  AttachmentModel({
    this.id,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    this.downloadUrl,
    this.description,
    this.createdAt,
    this.localFilePath,
  });

  /// Parse from OpenProject API response
  ///
  /// Example response structure:
  /// ```json
  /// {
  ///   "id": 123,
  ///   "fileName": "photo.jpg",
  ///   "fileSize": 1024000,
  ///   "contentType": "image/jpeg",
  ///   "description": "Issue photo",
  ///   "createdAt": "2024-01-15T10:30:00Z",
  ///   "_links": {
  ///     "downloadLocation": {
  ///       "href": "/api/v3/attachments/123/content"
  ///     }
  ///   }
  /// }
  /// ```
  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    final links = json['_links'] as Map<String, dynamic>?;
    final downloadLocation =
        links?['downloadLocation'] as Map<String, dynamic>?;
    final downloadUrl = downloadLocation?['href'] as String?;

    // Parse description - can be String or object with format/raw/html
    String? description;
    final descriptionObj = json['description'];
    if (descriptionObj is String) {
      description = descriptionObj;
    } else if (descriptionObj is Map<String, dynamic>) {
      description = descriptionObj['raw'] as String?;
    }

    return AttachmentModel(
      id: json['id'] as int?,
      fileName: json['fileName'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      downloadUrl: downloadUrl,
      description: description,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      localFilePath: json['localFilePath'] as String?,
    );
  }

  /// Create a copy with updated fields
  AttachmentModel copyWith({
    int? id,
    String? fileName,
    int? fileSize,
    String? contentType,
    String? downloadUrl,
    String? description,
    DateTime? createdAt,
    String? localFilePath,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      contentType: contentType ?? this.contentType,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  /// Convert to domain entity
  AttachmentEntity toEntity() {
    return AttachmentEntity(
      id: id,
      fileName: fileName,
      fileSize: fileSize,
      contentType: contentType,
      downloadUrl: downloadUrl,
      description: description,
      createdAt: createdAt,
      localFilePath: localFilePath,
    );
  }

  /// Convert to JSON (for serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileSize': fileSize,
      'contentType': contentType,
      'downloadUrl': downloadUrl,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'localFilePath': localFilePath,
    };
  }
}
