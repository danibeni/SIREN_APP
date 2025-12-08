import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/network/dio_client.dart';
import 'package:siren_app/features/issues/data/datasources/issue_local_datasource.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLogger extends Mock implements Logger {}

class MockDioClient extends Mock implements DioClient {}

class MockServerConfigService extends Mock implements ServerConfigService {}

void main() {
  late IssueLocalDataSource dataSource;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLogger mockLogger;
  late MockDioClient mockDioClient;
  late MockServerConfigService mockServerConfigService;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockLogger = MockLogger();
    mockDioClient = MockDioClient();
    mockServerConfigService = MockServerConfigService();
    dataSource = IssueLocalDataSource(
      secureStorage: mockSecureStorage,
      logger: mockLogger,
      dioClient: mockDioClient,
      serverConfigService: mockServerConfigService,
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
        // Mock getCachedIssues to return null (no previous cache)
        when(
          () => mockSecureStorage.read(key: 'cached_issues'),
        ).thenAnswer((_) async => null);

        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('Storage error'));
        when(() => mockLogger.warning(any())).thenReturn(null);

        // When
        await dataSource.cacheIssues(issues);

        // Then - Now called 1 time (the cacheIssues exception)
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

    group('cacheIssueDetails', () {
      test('should cache issue details successfully', () async {
        // Given
        final issueJson = {
          'id': 1,
          'subject': 'Test Issue',
          'description': {'raw': 'Test description'},
        };
        when(
          () => mockSecureStorage.write(
            key: 'issue_details_1',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockLogger.info(any())).thenReturn(null);

        // When
        await dataSource.cacheIssueDetails(1, issueJson);

        // Then
        verify(
          () => mockSecureStorage.write(
            key: 'issue_details_1',
            value: any(named: 'value'),
          ),
        ).called(1);
        verify(() => mockLogger.info(any())).called(1);
      });

      test('should log warning on cache failure', () async {
        // Given
        final issueJson = {'id': 1, 'subject': 'Test Issue'};
        when(
          () => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenThrow(Exception('Storage error'));
        when(() => mockLogger.warning(any())).thenReturn(null);

        // When
        await dataSource.cacheIssueDetails(1, issueJson);

        // Then
        verify(() => mockLogger.warning(any())).called(1);
      });
    });

    group('getCachedIssueDetails', () {
      test('should return cached issue details when available', () async {
        // Given
        final issueJson = {'id': 1, 'subject': 'Cached Issue'};
        when(
          () => mockSecureStorage.read(key: 'issue_details_1'),
        ).thenAnswer((_) async => jsonEncode(issueJson));

        // When
        final result = await dataSource.getCachedIssueDetails(1);

        // Then
        expect(result, isNotNull);
        expect(result!['id'], 1);
        expect(result['subject'], 'Cached Issue');
      });

      test('should return null when no cache exists', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'issue_details_999'),
        ).thenAnswer((_) async => null);

        // When
        final result = await dataSource.getCachedIssueDetails(999);

        // Then
        expect(result, isNull);
      });
    });

    group('cacheAttachments', () {
      test('should cache attachments successfully', () async {
        // Given
        final attachments = [
          {
            'id': 1,
            'fileName': 'test.pdf',
            'fileSize': 1024,
            'contentType': 'application/pdf',
          },
        ];
        when(
          () => mockSecureStorage.write(
            key: 'attachments_1',
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        when(() => mockLogger.info(any())).thenReturn(null);

        // When
        await dataSource.cacheAttachments(1, attachments);

        // Then
        verify(
          () => mockSecureStorage.write(
            key: 'attachments_1',
            value: any(named: 'value'),
          ),
        ).called(1);
        verify(() => mockLogger.info(any())).called(1);
      });
    });

    group('getCachedAttachments', () {
      test('should return cached attachments when available', () async {
        // Given
        final attachments = [
          {
            'id': 1,
            'fileName': 'test.pdf',
            'fileSize': 1024,
            'contentType': 'application/pdf',
          },
        ];
        when(
          () => mockSecureStorage.read(key: 'attachments_1'),
        ).thenAnswer((_) async => jsonEncode(attachments));

        // When
        final result = await dataSource.getCachedAttachments(1);

        // Then
        expect(result, isNotNull);
        expect(result!.length, 1);
        expect(result[0]['fileName'], 'test.pdf');
      });

      test('should return null when no cache exists', () async {
        // Given
        when(
          () => mockSecureStorage.read(key: 'attachments_999'),
        ).thenAnswer((_) async => null);

        // When
        final result = await dataSource.getCachedAttachments(999);

        // Then
        expect(result, isNull);
      });
    });

    group('clearIssueDetails', () {
      test('should clear issue details and attachments', () async {
        // Given
        when(
          () => mockSecureStorage.delete(key: any(named: 'key')),
        ).thenAnswer((_) async {});
        when(() => mockLogger.info(any())).thenReturn(null);

        // When
        await dataSource.clearIssueDetails(1);

        // Then
        verify(
          () => mockSecureStorage.delete(key: 'issue_details_1'),
        ).called(1);
        verify(() => mockSecureStorage.delete(key: 'attachments_1')).called(1);
        verify(() => mockLogger.info(any())).called(1);
      });
    });
  });
}
