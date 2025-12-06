import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

/// Local data source for storing Work Package Type configuration and statuses.
@lazySingleton
class WorkPackageTypeLocalDataSource {
  WorkPackageTypeLocalDataSource({
    required FlutterSecureStorage secureStorage,
    required Logger logger,
  }) : _secureStorage = secureStorage,
       _logger = logger;

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  static const _typeKey = 'work_package_type';
  static const _statusPrefix = 'work_package_statuses_';

  Future<String> getSelectedType() async {
    final stored = await _secureStorage.read(key: _typeKey);
    if (stored == null || stored.isEmpty) {
      return 'Issue';
    }
    return stored;
  }

  Future<void> setSelectedType(String typeName) async {
    await _secureStorage.write(key: _typeKey, value: typeName);
  }

  Future<void> cacheStatuses(
    String typeName,
    List<Map<String, dynamic>> statuses,
  ) async {
    final key = _statusKey(typeName);
    await _secureStorage.write(key: key, value: jsonEncode(statuses));
  }

  Future<List<Map<String, dynamic>>?> getCachedStatuses(String typeName) async {
    final key = _statusKey(typeName);
    final raw = await _secureStorage.read(key: key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.warning('Failed to decode cached statuses: $e');
      return null;
    }
  }

  Future<void> clearStatusesCache(String typeName) async {
    await _secureStorage.delete(key: _statusKey(typeName));
  }

  String _statusKey(String typeName) {
    final normalized = typeName.trim().toLowerCase();
    return '$_statusPrefix$normalized';
  }
}
