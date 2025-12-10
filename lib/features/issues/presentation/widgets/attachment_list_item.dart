import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:siren_app/core/i18n/generated/app_localizations.dart';
import 'package:siren_app/features/issues/presentation/widgets/file_type_icon.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentListItem extends StatelessWidget {
  final String fileName;
  final String? mimeType;
  final String? downloadUrl;
  final String? localFilePath;
  final VoidCallback? onTap;

  const AttachmentListItem({
    super.key,
    required this.fileName,
    this.mimeType,
    this.downloadUrl,
    this.localFilePath,
    this.onTap,
  });

  Future<void> _openAttachment(BuildContext context) async {
    // PRIORITY 1: Use local file if available
    if (localFilePath != null && localFilePath!.isNotEmpty) {
      try {
        final file = File(localFilePath!);
        if (await file.exists()) {
          // Use open_filex package which handles FileProvider automatically on Android
          final result = await OpenFilex.open(localFilePath!);

          if (result.type != ResultType.done) {
            // File couldn't be opened
            String message;
            switch (result.type) {
              case ResultType.noAppToOpen:
                message = 'No app available to open this file type';
                break;
              case ResultType.fileNotFound:
                message = 'Cached file not found';
                break;
              case ResultType.error:
                message = result.message.isNotEmpty
                    ? 'Error opening file: ${result.message}'
                    : 'Error opening file: Unknown error';
                break;
              default:
                message = 'Unable to open file';
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            // Fall through to download URL if local file failed
          } else {
            // Successfully opened, exit early
            return;
          }
        } else {
          // File doesn't exist, fall through to download URL
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                      .issueAttachmentCachedFileNotFound,
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        // Error opening local file, fall through to download URL
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                    .issueAttachmentErrorOpeningCached(e.toString()),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }

    // PRIORITY 2: Use download URL if no local file
    if (downloadUrl == null || downloadUrl!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Attachment not available offline. Connect to download.',
            ),
          ),
        );
      }
      return;
    }

    final uri = Uri.parse(downloadUrl!);

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this file type')),
          );
        }
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .issueAttachmentErrorOpeningFile(e.toString()),
            ),
          ),
        );
      }
    }
  }

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show cached indicator if file is cached locally
          if (localFilePath != null)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.offline_pin, size: 16, color: Colors.green),
            ),
          // Show open icon if downloadable
          if (downloadUrl != null || localFilePath != null)
            const Icon(Icons.open_in_new, size: 18),
        ],
      ),
      onTap: onTap ?? () => _openAttachment(context),
    );
  }
}
