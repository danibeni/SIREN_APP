import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/get_attachments_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late GetAttachmentsUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = GetAttachmentsUseCase(mockRepository);
  });

  group('GetAttachmentsUseCase', () {
    const issueId = 1;

    final attachments = [
      AttachmentEntity(
        id: 1,
        fileName: 'photo.jpg',
        fileSize: 1024000,
        contentType: 'image/jpeg',
        downloadUrl: 'https://example.com/attachments/1/content',
        createdAt: DateTime(2024, 1, 15),
      ),
      AttachmentEntity(
        id: 2,
        fileName: 'document.pdf',
        fileSize: 2048000,
        contentType: 'application/pdf',
        downloadUrl: 'https://example.com/attachments/2/content',
        createdAt: DateTime(2024, 1, 16),
      ),
    ];

    test(
      'should return List<AttachmentEntity> when repository call is successful',
      () async {
        // Given
        when(
          () => mockRepository.getAttachments(issueId),
        ).thenAnswer((_) async => Right(attachments));

        // When
        final result = await useCase(issueId);

        // Then
        expect(result.isRight(), true);
        result.fold((failure) => fail('Expected success but got failure'), (
          returnedAttachments,
        ) {
          expect(returnedAttachments.length, 2);
          expect(returnedAttachments[0].fileName, 'photo.jpg');
          expect(returnedAttachments[1].fileName, 'document.pdf');
        });
        verify(() => mockRepository.getAttachments(issueId)).called(1);
      },
    );

    test('should return empty list when issue has no attachments', () async {
      // Given
      when(
        () => mockRepository.getAttachments(issueId),
      ).thenAnswer((_) async => const Right([]));

      // When
      final result = await useCase(issueId);

      // Then
      expect(result.isRight(), true);
      result.fold((failure) => fail('Expected success but got failure'), (
        returnedAttachments,
      ) {
        expect(returnedAttachments, isEmpty);
      });
      verify(() => mockRepository.getAttachments(issueId)).called(1);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Given
      when(() => mockRepository.getAttachments(issueId)).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );

      // When
      final result = await useCase(issueId);

      // Then
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, 'No internet connection');
      }, (_) => fail('Expected failure but got success'));
      verify(() => mockRepository.getAttachments(issueId)).called(1);
    });

    test('should return ServerFailure when server error occurs', () async {
      // Given
      when(
        () => mockRepository.getAttachments(issueId),
      ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      // When
      final result = await useCase(issueId);

      // Then
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'Server error');
      }, (_) => fail('Expected failure but got success'));
      verify(() => mockRepository.getAttachments(issueId)).called(1);
    });

    test('should return NotFoundFailure when issue not found', () async {
      // Given
      when(
        () => mockRepository.getAttachments(issueId),
      ).thenAnswer((_) async => const Left(NotFoundFailure('Issue not found')));

      // When
      final result = await useCase(issueId);

      // Then
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'Issue not found');
      }, (_) => fail('Expected failure but got success'));
      verify(() => mockRepository.getAttachments(issueId)).called(1);
    });

    test('should call repository with correct issue ID', () async {
      // Given
      const testIssueId = 42;
      when(
        () => mockRepository.getAttachments(testIssueId),
      ).thenAnswer((_) async => const Right([]));

      // When
      await useCase(testIssueId);

      // Then
      verify(() => mockRepository.getAttachments(testIssueId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
