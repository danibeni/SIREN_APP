import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/network/dio_client.dart';

/// Local data source for caching issues (limited to ~3 screenfuls for MVP).
///
/// For MVP: Simple cache without offline modification tracking.
/// Post-MVP: Will include sync status and conflict resolution.
@lazySingleton
class IssueLocalDataSource {
  IssueLocalDataSource({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
    required DioClient dioClient,
    required ServerConfigService serverConfigService,
  }) : _secureStorage = secureStorage,
       _logger = logger,
       _dioClient = dioClient,
       _serverConfigService = serverConfigService;

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;
  final DioClient _dioClient;
  final ServerConfigService _serverConfigService;

  static const _cacheKey = 'cached_issues';
  static const _cacheTimestampKey = 'cached_issues_timestamp';

  /// Cache size: approximately 3 screenfuls (~150 items, 50 per screenful)
  static const int maxCacheSize = 150;

  /// Cache issues to local storage (limited to maxCacheSize)
  ///
  /// Also cleans up cached details for issues that are no longer in the list
  Future<void> cacheIssues(List<Map<String, dynamic>> issues) async {
    try {
      // Get current cached list to identify removed issues
      final currentCached = await getCachedIssues();
      final currentIds =
          currentCached?.map((i) => i['id'] as int?).whereType<int>().toSet() ??
          {};
      final newIds = issues
          .map((i) => i['id'] as int?)
          .whereType<int>()
          .toSet();

      // Clear details for issues removed from list
      // (They are no longer in the 3-screenful cache)
      final removedIds = currentIds.difference(newIds);
      for (final id in removedIds) {
        await clearIssueDetails(id);
        _logger.info('Cleared cached details for removed issue $id');
      }

      // Limit to maxCacheSize (3 screenfuls)
      final limitedIssues = issues.take(maxCacheSize).toList();

      await _secureStorage.write(
        key: _cacheKey,
        value: jsonEncode(limitedIssues),
      );
      await _secureStorage.write(
        key: _cacheTimestampKey,
        value: DateTime.now().toIso8601String(),
      );

      _logger.info('Cached ${limitedIssues.length} issues locally');
    } catch (e) {
      _logger.warning('Failed to cache issues: $e');
    }
  }

  /// Retrieve cached issues from local storage
  Future<List<Map<String, dynamic>>?> getCachedIssues() async {
    try {
      final raw = await _secureStorage.read(key: _cacheKey);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.warning('Failed to read cached issues: $e');
      return null;
    }
  }

  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final raw = await _secureStorage.read(key: _cacheTimestampKey);
      if (raw == null) return null;
      return DateTime.parse(raw);
    } catch (e) {
      _logger.warning('Failed to read cache timestamp: $e');
      return null;
    }
  }

  /// Clear all cached issues
  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _cacheKey);
      await _secureStorage.delete(key: _cacheTimestampKey);
      _logger.info('Cleared issue cache');
    } catch (e) {
      _logger.warning('Failed to clear cache: $e');
    }
  }

  /// Check if cache exists
  Future<bool> hasCachedIssues() async {
    final cached = await _secureStorage.read(key: _cacheKey);
    return cached != null;
  }

  /// Cache individual issue details (including attachments)
  ///
  /// Used for offline access to complete issue information
  Future<void> cacheIssueDetails(
    int issueId,
    Map<String, dynamic> issueJson,
  ) async {
    try {
      final key = 'issue_details_$issueId';
      await _secureStorage.write(key: key, value: jsonEncode(issueJson));
      _logger.info('Cached details for issue $issueId');
    } catch (e) {
      _logger.warning('Failed to cache issue details: $e');
    }
  }

  /// Get cached issue details
  Future<Map<String, dynamic>?> getCachedIssueDetails(int issueId) async {
    try {
      final key = 'issue_details_$issueId';
      final raw = await _secureStorage.read(key: key);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      _logger.warning('Failed to read cached issue details: $e');
      return null;
    }
  }

  /// Cache attachments for an issue
  Future<void> cacheAttachments(
    int issueId,
    List<Map<String, dynamic>> attachments,
  ) async {
    try {
      final key = 'attachments_$issueId';
      await _secureStorage.write(key: key, value: jsonEncode(attachments));
      _logger.info(
        'Cached ${attachments.length} attachments for issue $issueId',
      );
    } catch (e) {
      _logger.warning('Failed to cache attachments: $e');
    }
  }

  /// Get cached attachments
  Future<List<Map<String, dynamic>>?> getCachedAttachments(int issueId) async {
    try {
      final key = 'attachments_$issueId';
      final raw = await _secureStorage.read(key: key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.warning('Failed to read cached attachments: $e');
      return null;
    }
  }

  /// Clear cached issue details (when issue is removed from list cache)
  Future<void> clearIssueDetails(int issueId) async {
    try {
      final detailsKey = 'issue_details_$issueId';
      await _secureStorage.delete(key: detailsKey);
      await clearAttachments(issueId);
      _logger.info('Cleared cached details for issue $issueId');
    } catch (e) {
      _logger.warning('Failed to clear issue details: $e');
    }
  }

  /// Clear cached attachments (also clears local files)
  Future<void> clearAttachments(int issueId) async {
    try {
      final key = 'attachments_$issueId';
      await _secureStorage.delete(key: key);
      // Also clear local files
      await clearLocalAttachments(issueId);
    } catch (e) {
      _logger.warning('Failed to clear attachments: $e');
    }
  }

  /// Download and cache attachment file locally
  ///
  /// Downloads attachment if size <= 5MB and stores in app's cache directory
  /// Returns local file path if successful, null otherwise
  Future<String?> downloadAndCacheAttachment({
    required int issueId,
    required int attachmentId,
    required String downloadUrl,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      // Limit: 5MB (5 * 1024 * 1024 bytes)
      const maxSize = 5 * 1024 * 1024;
      if (fileSize > maxSize) {
        _logger.info(
          'Attachment $attachmentId exceeds 5MB limit ($fileSize bytes), skipping download',
        );
        return null;
      }

      // Get app cache directory
      final cacheDir = await getApplicationCacheDirectory();
      final attachmentsDir = Directory(
        path.join(cacheDir.path, 'attachments', issueId.toString()),
      );

      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Sanitize filename to avoid path issues
      final sanitizedFileName = fileName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final localFilePath = path.join(
        attachmentsDir.path,
        '${attachmentId}_$sanitizedFileName',
      );

      // Check if file already exists
      final file = File(localFilePath);
      if (await file.exists()) {
        _logger.info(
          'Attachment $attachmentId already cached at $localFilePath',
        );
        return localFilePath;
      }

      // Get Dio instance with authentication
      final dio = await _getDio();

      // Download file
      _logger.info('Downloading attachment $attachmentId from $downloadUrl');
      final response = await dio.download(
        downloadUrl,
        localFilePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 400,
        ),
      );

      if (response.statusCode == 200) {
        // Verify file was actually written
        final downloadedFile = File(localFilePath);
        if (await downloadedFile.exists()) {
          final downloadedSize = await downloadedFile.length();
          _logger.info(
            'Successfully downloaded and cached attachment $attachmentId '
            '($downloadedSize bytes)',
          );
          return localFilePath;
        } else {
          _logger.severe(
            'Download reported success but file does not exist at $localFilePath',
          );
          return null;
        }
      } else {
        _logger.warning(
          'Failed to download attachment $attachmentId: HTTP ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      _logger.warning('Failed to download attachment $attachmentId: $e');
      return null;
    }
  }

  /// Get local file path for cached attachment
  Future<String?> getLocalAttachmentPath({
    required int issueId,
    required int attachmentId,
    required String fileName,
  }) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final sanitizedFileName = fileName.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final localFilePath = path.join(
        cacheDir.path,
        'attachments',
        issueId.toString(),
        '${attachmentId}_$sanitizedFileName',
      );

      final file = File(localFilePath);
      if (await file.exists()) {
        return localFilePath;
      }
      return null;
    } catch (e) {
      _logger.warning('Failed to get local attachment path: $e');
      return null;
    }
  }

  /// Clear local attachment files for an issue
  Future<void> clearLocalAttachments(int issueId) async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final attachmentsDir = Directory(
        path.join(cacheDir.path, 'attachments', issueId.toString()),
      );

      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
        _logger.info('Cleared local attachments for issue $issueId');
      }
    } catch (e) {
      _logger.warning('Failed to clear local attachments: $e');
    }
  }

  /// Save issue modifications locally for offline synchronization
  ///
  /// Stores local changes with metadata indicating pending sync
  /// Returns the stored issue JSON
  Future<Map<String, dynamic>> saveLocalModifications(
    Map<String, dynamic> issue,
  ) async {
    try {
      final issueId = issue['id'] as int?;
      if (issueId == null) {
        throw Exception('Issue ID is required for local modifications');
      }

      // Mark as having pending sync
      final modifiedIssue = Map<String, dynamic>.from(issue);
      modifiedIssue['hasPendingSync'] = true;
      modifiedIssue['localModifiedAt'] = DateTime.now().toIso8601String();

      // Store in separate pending sync storage
      final pendingKey = 'pending_sync_$issueId';
      await _secureStorage.write(
        key: pendingKey,
        value: jsonEncode(modifiedIssue),
      );

      // Also cache the modified issue details
      await cacheIssueDetails(issueId, modifiedIssue);

      _logger.info('Saved local modifications for issue $issueId');
      return modifiedIssue;
    } catch (e) {
      _logger.severe('Failed to save local modifications: $e');
      rethrow;
    }
  }

  /// Get issue with pending local modifications
  ///
  /// Returns the locally modified issue if it has pending changes
  /// Returns null if no pending modifications exist
  Future<Map<String, dynamic>?> getIssueWithPendingSync(int issueId) async {
    try {
      final pendingKey = 'pending_sync_$issueId';
      final pendingJson = await _secureStorage.read(key: pendingKey);

      if (pendingJson == null) {
        return null;
      }

      final issue = jsonDecode(pendingJson) as Map<String, dynamic>;
      _logger.info('Retrieved pending modifications for issue $issueId');
      return issue;
    } catch (e) {
      _logger.warning('Failed to get pending modifications: $e');
      return null;
    }
  }

  /// Clear pending sync status for an issue
  ///
  /// Removes local modifications and restores server version
  Future<void> clearPendingSync(int issueId) async {
    try {
      final pendingKey = 'pending_sync_$issueId';
      await _secureStorage.delete(key: pendingKey);

      // Re-cache the server version (if available)
      final serverVersion = await getCachedIssueDetails(issueId);
      if (serverVersion != null) {
        final cleanVersion = Map<String, dynamic>.from(serverVersion);
        cleanVersion['hasPendingSync'] = false;
        await cacheIssueDetails(issueId, cleanVersion);
      }

      _logger.info('Cleared pending sync status for issue $issueId');
    } catch (e) {
      _logger.warning('Failed to clear pending sync: $e');
    }
  }

  /// Get all issues with pending sync status
  ///
  /// Returns list of issue IDs that have pending local modifications
  Future<List<int>> getIssuesWithPendingSync() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final pendingIds = <int>[];

      for (final key in allKeys.keys) {
        if (key.startsWith('pending_sync_')) {
          final idStr = key.replaceFirst('pending_sync_', '');
          final id = int.tryParse(idStr);
          if (id != null) {
            pendingIds.add(id);
          }
        }
      }

      _logger.info('Found ${pendingIds.length} issues with pending sync');
      return pendingIds;
    } catch (e) {
      _logger.warning('Failed to get issues with pending sync: $e');
      return [];
    }
  }

  /// Get configured Dio instance with server baseUrl
  Future<Dio> _getDio() async {
    final serverUrlResult = await _serverConfigService.getServerUrl();
    return serverUrlResult.fold(
      (failure) {
        _logger.severe('Failed to get server URL: ${failure.message}');
        throw Exception('Server URL not configured');
      },
      (serverUrl) {
        if (serverUrl == null || serverUrl.isEmpty) {
          throw Exception('Server URL not configured');
        }
        return _dioClient.createDio(serverUrl);
      },
    );
  }
}
