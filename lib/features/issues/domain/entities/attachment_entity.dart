import 'package:equatable/equatable.dart';

/// Pure business entity representing an Attachment
///
/// Domain entity following Clean Architecture principles.
/// Contains no framework dependencies.
class AttachmentEntity extends Equatable {
  final int? id; // Null for new attachments not yet uploaded
  final String fileName;
  final int fileSize;
  final String contentType;
  final String? downloadUrl; // Null for new attachments
  final String? description;
  final DateTime? createdAt; // Null for new attachments
  final String? localFilePath; // Path to locally cached file

  const AttachmentEntity({
    this.id,
    required this.fileName,
    required this.fileSize,
    required this.contentType,
    this.downloadUrl,
    this.description,
    this.createdAt,
    this.localFilePath,
  });

  @override
  List<Object?> get props => [
    id,
    fileName,
    fileSize,
    contentType,
    downloadUrl,
    description,
    createdAt,
    localFilePath,
  ];

  /// Create a copy with updated fields
  AttachmentEntity copyWith({
    int? id,
    String? fileName,
    int? fileSize,
    String? contentType,
    String? downloadUrl,
    String? description,
    DateTime? createdAt,
    String? localFilePath,
  }) {
    return AttachmentEntity(
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
}
