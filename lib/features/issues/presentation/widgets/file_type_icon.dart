import 'package:flutter/material.dart';

enum FileType { pdf, image, markdown, document, text, generic }

class FileTypeIcon extends StatelessWidget {
  final String? mimeType;
  final String? fileName;

  const FileTypeIcon({super.key, this.mimeType, this.fileName});

  @override
  Widget build(BuildContext context) {
    final type = _getFileType();

    switch (type) {
      case FileType.pdf:
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case FileType.image:
        return const Icon(Icons.image, color: Colors.blue);
      case FileType.markdown:
        return const Icon(Icons.description, color: Colors.grey);
      case FileType.document:
        return const Icon(Icons.description, color: Colors.blue);
      case FileType.text:
        return const Icon(Icons.text_snippet, color: Colors.grey);
      case FileType.generic:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  FileType _getFileType() {
    final mime = mimeType?.toLowerCase() ?? '';
    final name = fileName?.toLowerCase() ?? '';

    if (mime.contains('pdf') || name.endsWith('.pdf')) {
      return FileType.pdf;
    }
    if (mime.contains('image') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.gif')) {
      return FileType.image;
    }
    if (mime.contains('markdown') || name.endsWith('.md')) {
      return FileType.markdown;
    }
    if (mime.contains('document') ||
        name.endsWith('.doc') ||
        name.endsWith('.docx')) {
      return FileType.document;
    }
    if (mime.contains('text') || name.endsWith('.txt')) {
      return FileType.text;
    }

    return FileType.generic;
  }
}
