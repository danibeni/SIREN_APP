import 'package:flutter/material.dart';
import 'package:siren_app/features/issues/presentation/widgets/file_type_icon.dart';

class AttachmentListItem extends StatelessWidget {
  final String fileName;
  final String? mimeType;
  final VoidCallback? onTap;

  const AttachmentListItem({
    super.key,
    required this.fileName,
    this.mimeType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FileTypeIcon(mimeType: mimeType, fileName: fileName),
      title: Text(
        fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
