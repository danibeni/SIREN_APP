import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/features/issues/data/datasources/issue_local_datasource.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLogger extends Mock implements Logger {}

void main() {
  late IssueLocalDataSource dataSource;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLogger mockLogger;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockLogger = MockLogger();
    dataSource = IssueLocalDataSource(
      secureStorage: mockSecureStorage,
      logger: mockLogger,
    );
  });

  group('IssueLocalDataSource', () {
    group('cacheIssues', () {
      test('should store issues in secure storage with timestamp', () async {
        // Given
        final issues = [
          {'id': 1, 'subject': 'Test Issue 1'},
          {'id': 2, 'subject': 'Test Issue 2'},
        ];
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        // When
        await dataSource.cacheIssues(issues);

        // Then
        verify(
          () => mockSecureStorage.write(
            key: 'cached_issues',
            value: jsonEncode(issues),
          ),
        ).called(1);
        verify(
          () => mockSecureStorage.write(
            key: 'cached_issues_timestamp',
            value: any(named: 'value'),
          ),
        ).called(1);
      });

      test('should limit cache to maxCacheSize (150 items)', () async {
        // Given
        final issues = List.generate(
          200,
          (i) => {'id': i, 'subject': 'Issue $i'},
        );
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        // When
        await dataSource.cacheIssues(issues);

        // Then
        final captured =
            verify(
                  () => mockSecureStorage.write(
                    key: 'cached_issues',
                    value: captureAny(named: 'value'),
                  ),
                ).captured.single
                as String;

        final cachedIssues = jsonDecode(captured) as List;
        expect(cachedIssues.length, equals(150));
      });

      test('should log warning on cache failure', () async {
        // Given
        final issues = [
          {'id': 1, 'subject': 'Test Issue'},
        ];
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('Storage error'));
        when(() => mockLogger.warning(any())).thenReturn(null);

        // When
        await dataSource.cacheIssues(issues);

        // Then
        verify(() => mockLogger.warning(any())).called(1);
      });
    });

    group('getCachedIssues', () {
      test('should return cached issues when available', () async {
        // Given
        final issues = [
          {'id': 1, 'subject': 'Cached Issue 1'},
          {'id': 2, 'subject': 'Cached Issue 2'},
        ];
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => jsonEncode(issues));

        // When
        final result = await dataSource.getCachedIssues();

        // Then
        expect(result, equals(issues));
      });

      test('should return null when no cache exists', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => null);

        // When
        final result = await dataSource.getCachedIssues();

        // Then
        expect(result, isNull);
      });

      test('should return null on decode error', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => 'invalid json');
        when(() => mockLogger.warning(any())).thenReturn(null);

        // When
        final result = await dataSource.getCachedIssues();

        // Then
        expect(result, isNull);
        verify(() => mockLogger.warning(any())).called(1);
      });
    });

    group('getCacheTimestamp', () {
      test('should return timestamp when available', () async {
        // Given
        final timestamp = DateTime(2025, 12, 6, 10, 30);
        when(
          () => mockSecureStorage.read(key: 'cached_issues_timestamp'),
        ).thenAnswer((_) async => timestamp.toIso8601String());

        // When
        final result = await dataSource.getCacheTimestamp();

        // Then
        expect(result, equals(timestamp));
      });

      test('should return null when no timestamp exists', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'cached_issues_timestamp'),
        ).thenAnswer((_) async => null);

        // When
        final result = await dataSource.getCacheTimestamp();

        // Then
        expect(result, isNull);
      });
    });

    group('clearCache', () {
      test('should delete cached issues and timestamp', () async {
        // Given
        when(
          () => mockSecureStorage.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});
        when(() => mockLogger.info(any())).thenReturn(null);

        // When
        await dataSource.clearCache();

        // Then
        verify(() => mockSecureStorage.delete(key: 'cached_issues')).called(1);
        verify(
          () => mockSecureStorage.delete(key: 'cached_issues_timestamp'),
        ).called(1);
        verify(() => mockLogger.info(any())).called(1);
      });
    });

    group('hasCachedIssues', () {
      test('should return true when cache exists', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => '[]');

        // When
        final result = await dataSource.hasCachedIssues();

        // Then
        expect(result, isTrue);
      });

      test('should return false when cache does not exist', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => null);

        // When
        final result = await dataSource.hasCachedIssues();

        // Then
        expect(result, isFalse);
      });
    });
  });
}
