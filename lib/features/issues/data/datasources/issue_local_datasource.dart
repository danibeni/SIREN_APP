import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

/// Local data source for caching issues (limited to ~3 screenfuls for MVP).
///
/// For MVP: Simple cache without offline modification tracking.
/// Post-MVP: Will include sync status and conflict resolution.
@lazySingleton
class IssueLocalDataSource {
  IssueLocalDataSource({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
  }) : _secureStorage = secureStorage,
       _logger = logger;

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const _cacheKey = 'cached_issues';
  static const _cacheTimestampKey = 'cached_issues_timestamp';

  /// Cache size: approximately 3 screenfuls (~150 items, 50 per screenful)
  static const int maxCacheSize = 150;

  /// Cache issues to local storage (limited to maxCacheSize)
  Future<void> cacheIssues(List<Map<String, dynamic>> issues) async {
    try {
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
}
