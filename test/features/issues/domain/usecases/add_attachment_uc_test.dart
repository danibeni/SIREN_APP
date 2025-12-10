import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import 'package:siren_app/features/issues/domain/usecases/add_attachment_params.dart';
import 'package:siren_app/features/issues/domain/usecases/add_attachment_uc.dart';

class MockIssueRepository extends Mock implements IssueRepository {}

void main() {
  late AddAttachmentUseCase useCase;
  late MockIssueRepository mockRepository;

  setUp(() {
    mockRepository = MockIssueRepository();
    useCase = AddAttachmentUseCase(mockRepository);
  });

  group('AddAttachmentUseCase', () {
    const tIssueId = 1;
    const tFilePath = '/path/to/image.jpg';
    const tFileName = 'image.jpg';
    const tDescription = 'Test attachment';

    final tAttachment = AttachmentEntity(
      id: 123,
      fileName: tFileName,
      fileSize: 1024,
      contentType: 'image/jpeg',
      downloadUrl: 'https://example.com/attachments/123',
      description: tDescription,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return AttachmentEntity when upload succeeds', () async {
      // Given
      final params = AddAttachmentParams(
        issueId: tIssueId,
        filePath: tFilePath,
        fileName: tFileName,
        description: tDescription,
      );

      when(
        () => mockRepository.addAttachment(
          issueId: any(named: 'issueId'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => Right(tAttachment));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tAttachment));
      verify(
        () => mockRepository.addAttachment(
          issueId: tIssueId,
          filePath: tFilePath,
          fileName: tFileName,
          description: tDescription,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Given
      final params = AddAttachmentParams(
        issueId: tIssueId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      when(
        () => mockRepository.addAttachment(
          issueId: any(named: 'issueId'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure('No internet connection')),
      );

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return ServerFailure when server error occurs', () async {
      // Given
      final params = AddAttachmentParams(
        issueId: tIssueId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      when(
        () => mockRepository.addAttachment(
          issueId: any(named: 'issueId'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('Server error')));

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should return ValidationFailure when file is too large', () async {
      // Given
      final params = AddAttachmentParams(
        issueId: tIssueId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      when(
        () => mockRepository.addAttachment(
          issueId: any(named: 'issueId'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => const Left(ValidationFailure('File is too large')),
      );

      // When
      final result = await useCase(params);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test(
      'should call repository addAttachment method with correct parameters',
      () async {
        // Given
        final params = AddAttachmentParams(
          issueId: tIssueId,
          filePath: tFilePath,
          fileName: tFileName,
          description: tDescription,
        );

        when(
          () => mockRepository.addAttachment(
            issueId: any(named: 'issueId'),
            filePath: any(named: 'filePath'),
            fileName: any(named: 'fileName'),
            description: any(named: 'description'),
          ),
        ).thenAnswer((_) async => Right(tAttachment));

        // When
        await useCase(params);

        // Then
        verify(
          () => mockRepository.addAttachment(
            issueId: tIssueId,
            filePath: tFilePath,
            fileName: tFileName,
            description: tDescription,
          ),
        ).called(1);
      },
    );

    test('should work without description (optional parameter)', () async {
      // Given
      final params = AddAttachmentParams(
        issueId: tIssueId,
        filePath: tFilePath,
        fileName: tFileName,
      );

      when(
        () => mockRepository.addAttachment(
          issueId: any(named: 'issueId'),
          filePath: any(named: 'filePath'),
          fileName: any(named: 'fileName'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async => Right(tAttachment));

      // When
      final result = await useCase(params);

      // Then
      expect(result, Right(tAttachment));
      verify(
        () => mockRepository.addAttachment(
          issueId: tIssueId,
          filePath: tFilePath,
          fileName: tFileName,
          description: null,
        ),
      ).called(1);
    });
  });
}
