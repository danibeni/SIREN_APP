import 'package:dartz/dartz.dart';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import '../datasources/issue_local_datasource.dart';
import '../datasources/issue_remote_datasource.dart';
import '../models/attachment_model.dart';
import '../models/issue_model.dart';

/// Implementation of IssueRepository
///
/// Connects the domain layer with the data layer by calling the remote
/// data source and mapping responses to domain entities.
/// For MVP: Implements basic cache (3 screenfuls) with offline read access.
@LazySingleton(as: IssueRepository)
class IssueRepositoryImpl implements IssueRepository {
  final IssueRemoteDataSource remoteDataSource;
  final IssueLocalDataSource localDataSource;
  final ServerConfigService serverConfigService;
  final Logger logger;

  IssueRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.serverConfigService,
    required this.logger,
  });

  @override
  Future<Either<Failure, IssueEntity>> createIssue({
    required String subject,
    String? description,
    required int equipment,
    required int group,
    required PriorityLevel priorityLevel,
  }) async {
    try {
      final responseMap = await remoteDataSource.createIssue(
        subject: subject,
        description: description,
        equipment: equipment,
        group: group,
        priorityLevel: priorityLevel,
      );

      // Parse response and convert to entity
      final model = IssueModel.fromJson(responseMap);

      // Set group from parameter since API doesn't return it directly
      final entityWithGroup = model.copyWith(group: group).toEntity();

      return Right(entityWithGroup);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> getIssueById(int id) async {
    try {
      // Try to fetch from server
      final responseMap = await remoteDataSource.getIssueById(id);

      // Cache the full issue details (including embedded attachments)
      await localDataSource.cacheIssueDetails(id, responseMap);

      // Extract and cache attachments metadata if embedded
      // Note: Files are downloaded only when caching the issue list, not here
      try {
        final embeddedAttachments = await _extractAttachmentsFromWorkPackage(
          responseMap,
        );
        if (embeddedAttachments.isNotEmpty) {
          final attachmentsJson = embeddedAttachments
              .map(
                (entity) => {
                  'id': entity.id,
                  'fileName': entity.fileName,
                  'fileSize': entity.fileSize,
                  'contentType': entity.contentType,
                  'downloadUrl': entity.downloadUrl,
                  'description': entity.description,
                  'createdAt': entity.createdAt?.toIso8601String(),
                },
              )
              .toList();
          await localDataSource.cacheAttachments(id, attachmentsJson);
        }
      } catch (e) {
        logger.warning('Failed to cache attachments for issue $id: $e');
      }

      final model = IssueModel.fromJson(responseMap);
      return Right(model.toEntity());
    } on NetworkFailure catch (e) {
      // Try to load from cache when offline
      logger.warning(
        'Network failure, attempting to load issue $id from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedIssueDetails(id);
        if (cached != null) {
          logger.info('Loaded issue $id from cache');
          final model = IssueModel.fromJson(cached);
          return Right(model.toEntity());
        }
      } catch (cacheError) {
        logger.warning('Failed to load issue $id from cache: $cacheError');
      }
      return Left(
        NetworkFailure(
          'No internet connection and no cached data available for this issue',
        ),
      );
    } on ServerFailure catch (e) {
      // Also try cache for server errors (e.g., 401 when token expired)
      logger.warning(
        'Server failure, attempting to load issue $id from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedIssueDetails(id);
        if (cached != null) {
          logger.info('Loaded issue $id from cache (server error fallback)');
          final model = IssueModel.fromJson(cached);
          return Right(model.toEntity());
        }
      } catch (cacheError) {
        logger.warning('Failed to load issue $id from cache: $cacheError');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Extract attachments from work package response
  ///
  /// OpenProject embeds attachments in _embedded.attachments._embedded.elements
  /// when getting a work package. This method extracts them and converts
  /// relative URLs to absolute URLs.
  Future<List<AttachmentEntity>> _extractAttachmentsFromWorkPackage(
    Map<String, dynamic> workPackageJson,
  ) async {
    try {
      final embedded = workPackageJson['_embedded'] as Map<String, dynamic>?;
      final embeddedAttachments =
          embedded?['attachments'] as Map<String, dynamic>?;
      final attachmentsEmbedded =
          embeddedAttachments?['_embedded'] as Map<String, dynamic>?;
      final attachmentElements =
          attachmentsEmbedded?['elements'] as List<dynamic>?;

      if (attachmentElements == null || attachmentElements.isEmpty) {
        return [];
      }

      // Get server URL to convert relative URLs to absolute
      final serverUrlResult = await serverConfigService.getServerUrl();
      final serverUrl = serverUrlResult.fold((failure) {
        logger.warning('Failed to get server URL: ${failure.message}');
        return null;
      }, (url) => url);

      return attachmentElements
          .map((element) {
            try {
              final attachmentModel = AttachmentModel.fromJson(
                element as Map<String, dynamic>,
              );

              // Convert relative URL to absolute URL
              String? absoluteDownloadUrl = attachmentModel.downloadUrl;
              if (absoluteDownloadUrl != null &&
                  serverUrl != null &&
                  !absoluteDownloadUrl.startsWith('http')) {
                // Remove leading slash if present
                final relativePath = absoluteDownloadUrl.startsWith('/')
                    ? absoluteDownloadUrl.substring(1)
                    : absoluteDownloadUrl;
                // Remove trailing slash from server URL if present
                final baseUrl = serverUrl.endsWith('/')
                    ? serverUrl.substring(0, serverUrl.length - 1)
                    : serverUrl;
                absoluteDownloadUrl = '$baseUrl/$relativePath';
              }

              return attachmentModel
                  .copyWith(downloadUrl: absoluteDownloadUrl)
                  .toEntity();
            } catch (e) {
              logger.warning('Failed to parse attachment: $e');
              return null;
            }
          })
          .whereType<AttachmentEntity>()
          .toList();
    } catch (e) {
      logger.warning('Failed to extract attachments from work package: $e');
      return [];
    }
  }

  @override
  Future<Either<Failure, List<IssueEntity>>> getIssues({
    IssueStatus? status,
    int? equipmentId,
    PriorityLevel? priorityLevel,
    int? groupId,
    required String workPackageType,
  }) async {
    try {
      // Map IssueStatus to API status ID
      int? statusId;
      if (status != null) {
        statusId = _mapStatusToId(status);
      }

      // Resolve Work Package Type name to ID
      // Get all available types from OpenProject (global types, not project-specific)
      int? typeId;
      try {
        // Use getTypes() to get all global types instead of project-specific types
        final types = await remoteDataSource.getTypes();

        // Find type by name (case-insensitive)
        final matchingType = types.firstWhere(
          (type) =>
              (type['name'] as String?)?.toLowerCase() ==
              workPackageType.toLowerCase(),
          orElse: () => <String, dynamic>{},
        );

        if (matchingType.isNotEmpty) {
          typeId = matchingType['id'] as int?;
        } else {
          throw ServerFailure(
            'Work Package Type "$workPackageType" not found in OpenProject. '
            'Please configure a valid type in Settings.',
          );
        }
      } catch (e) {
        // If type resolution fails, return failure instead of continuing
        // This ensures we only show issues of the configured type
        return Left(
          ServerFailure('Failed to resolve Work Package Type: ${e.toString()}'),
        );
      }

      List<Map<String, dynamic>> responseList;
      try {
        // Try to fetch from server
        responseList = await remoteDataSource.getIssues(
          status: statusId,
          equipmentId: equipmentId,
          priorityLevel: priorityLevel,
          groupId: groupId,
          typeId: typeId,
        );

        // Cache the fetched issues (limited to 3 screenfuls)
        await localDataSource.cacheIssues(responseList);

        // Cache complete issue details (including attachments) for offline access
        for (final issueJson in responseList) {
          final issueId = issueJson['id'] as int?;
          if (issueId != null) {
            try {
              // Cache full issue details
              await localDataSource.cacheIssueDetails(issueId, issueJson);

              // Extract, download and cache attachments if embedded
              try {
                final embeddedAttachments =
                    await _extractAttachmentsFromWorkPackage(issueJson);
                if (embeddedAttachments.isNotEmpty) {
                  // Download and cache attachments locally (files <= 5MB)
                  final attachmentsWithLocalPaths = <AttachmentEntity>[];
                  for (final attachment in embeddedAttachments) {
                    if (attachment.downloadUrl != null && attachment.id != null) {
                      final localPath = await localDataSource.downloadAndCacheAttachment(
                        issueId: issueId,
                        attachmentId: attachment.id!,
                        downloadUrl: attachment.downloadUrl!,
                        fileName: attachment.fileName,
                        fileSize: attachment.fileSize,
                      );

                      // Update attachment with local path if downloaded
                      attachmentsWithLocalPaths.add(
                        attachment.copyWith(localFilePath: localPath),
                      );
                    } else {
                      attachmentsWithLocalPaths.add(attachment);
                    }
                  }

                  // Cache attachments metadata with local paths
                  final attachmentsJson = attachmentsWithLocalPaths
                      .map(
                        (entity) => {
                          'id': entity.id,
                          'fileName': entity.fileName,
                          'fileSize': entity.fileSize,
                          'contentType': entity.contentType,
                          'downloadUrl': entity.downloadUrl,
                          'description': entity.description,
                          'createdAt': entity.createdAt?.toIso8601String(),
                          'localFilePath': entity.localFilePath,
                        },
                      )
                      .toList();
                  await localDataSource.cacheAttachments(
                    issueId,
                    attachmentsJson,
                  );
                }
              } catch (e) {
                logger.warning(
                  'Failed to cache attachments for issue $issueId: $e',
                );
              }
            } catch (e) {
              logger.warning('Failed to cache details for issue $issueId: $e');
            }
          }
        }

        logger.info(
          'Successfully fetched and cached ${responseList.length} issues with details',
        );
      } on NetworkFailure catch (e) {
        // If network fails, try to load from cache
        logger.warning(
          'Network failure, attempting to load from cache: ${e.message}',
        );
        final cached = await localDataSource.getCachedIssues();
        if (cached != null && cached.isNotEmpty) {
          logger.info('Loaded ${cached.length} issues from cache');
          responseList = cached;
        } else {
          return Left(
            NetworkFailure(
              'No internet connection and no cached data available',
            ),
          );
        }
      }

      // Convert each map to entity and sort by updatedAt (most recent first)
      final entities = responseList
          .map((map) => IssueModel.fromJson(map).toEntity())
          .toList();

      // Sort by updatedAt, most recent first
      entities.sort((a, b) {
        if (a.updatedAt == null && b.updatedAt == null) return 0;
        if (a.updatedAt == null) return 1;
        if (b.updatedAt == null) return -1;
        return b.updatedAt!.compareTo(a.updatedAt!);
      });

      return Right(entities);
    } on ServerFailure catch (e) {
      // Try cache as fallback for server errors
      logger.warning(
        'Server failure, attempting to load from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedIssues();
        if (cached != null && cached.isNotEmpty) {
          logger.info(
            'Loaded ${cached.length} issues from cache after server failure',
          );
          final entities = cached
              .map((map) => IssueModel.fromJson(map).toEntity())
              .toList();
          entities.sort((a, b) {
            if (a.updatedAt == null && b.updatedAt == null) return 0;
            if (a.updatedAt == null) return 1;
            if (b.updatedAt == null) return -1;
            return b.updatedAt!.compareTo(a.updatedAt!);
          });
          return Right(entities);
        }
      } catch (cacheError) {
        logger.severe('Failed to load from cache: $cacheError');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> updateIssue({
    required int id,
    required int lockVersion,
    String? subject,
    String? description,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
  }) async {
    try {
      final responseMap = await remoteDataSource.updateIssue(
        id: id,
        lockVersion: lockVersion,
        subject: subject,
        description: description,
        priorityLevel: priorityLevel,
        status: status,
      );

      final model = IssueModel.fromJson(responseMap);
      return Right(model.toEntity());
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      await remoteDataSource.addAttachment(
        issueId: issueId,
        filePath: filePath,
        fileName: fileName,
        description: description,
      );
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<AttachmentEntity>>> getAttachments(
    int issueId,
  ) async {
    try {
      // First, try to get attachments from embedded work package response
      // OpenProject embeds attachments in _embedded.attachments._embedded.elements
      // when getting a work package
      try {
        final workPackageJson = await remoteDataSource.getIssueById(issueId);
        final embeddedAttachments = await _extractAttachmentsFromWorkPackage(
          workPackageJson,
        );
        if (embeddedAttachments.isNotEmpty) {
          // Cache attachments metadata (files downloaded only when caching list)
          final attachmentsJson = embeddedAttachments
              .map(
                (entity) => {
                  'id': entity.id,
                  'fileName': entity.fileName,
                  'fileSize': entity.fileSize,
                  'contentType': entity.contentType,
                  'downloadUrl': entity.downloadUrl,
                  'description': entity.description,
                  'createdAt': entity.createdAt?.toIso8601String(),
                },
              )
              .toList();
          await localDataSource.cacheAttachments(issueId, attachmentsJson);

          logger.info(
            'Extracted ${embeddedAttachments.length} attachments from work package response',
          );
          return Right(embeddedAttachments);
        }
      } catch (e) {
        logger.warning(
          'Failed to extract attachments from work package, trying separate endpoint: $e',
        );
      }

      // Fallback: Use separate attachments endpoint
      final attachmentsJson = await remoteDataSource.getAttachments(issueId);
      final attachments = attachmentsJson
          .map((json) => AttachmentModel.fromJson(json).toEntity())
          .toList();

      // Cache attachments metadata (files downloaded only when caching list)
      await localDataSource.cacheAttachments(issueId, attachmentsJson);

      logger.info(
        'Mapped ${attachments.length} attachments for issue $issueId',
      );
      return Right(attachments);
    } on NetworkFailure catch (e) {
      // Try to load from cache when offline
      logger.warning(
        'Network failure, attempting to load attachments from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedAttachments(issueId);
        if (cached != null && cached.isNotEmpty) {
          logger.info(
            'Loaded ${cached.length} attachments from cache for issue $issueId',
          );
          
          // Verify local files still exist and add paths if missing
          final attachments = <AttachmentEntity>[];
          for (final json in cached) {
            final attachment = AttachmentModel.fromJson(json).toEntity();

            // If no localFilePath in cache, try to find it
            if (attachment.localFilePath == null && attachment.id != null) {
              final localPath = await localDataSource.getLocalAttachmentPath(
                issueId: issueId,
                attachmentId: attachment.id!,
                fileName: attachment.fileName,
              );
              if (localPath != null) {
                attachments.add(attachment.copyWith(localFilePath: localPath));
              } else {
                attachments.add(attachment);
              }
            } else if (attachment.localFilePath != null) {
              // Verify file still exists
              final file = File(attachment.localFilePath!);
              if (await file.exists()) {
                attachments.add(attachment);
              } else {
                // File was deleted, remove local path
                logger.warning(
                  'Local file not found: ${attachment.localFilePath}, using remote URL',
                );
                attachments.add(attachment.copyWith(localFilePath: null));
              }
            } else {
              attachments.add(attachment);
            }
          }
          return Right(attachments);
        }
      } catch (cacheError) {
        logger.warning('Failed to load attachments from cache: $cacheError');
      }
      // Return empty list when offline with no cache (not an error)
      logger.info('No cached attachments available for issue $issueId');
      return const Right([]);
    } on ServerFailure catch (e) {
      // Also try cache for server errors (e.g., 401)
      logger.warning(
        'Server failure, attempting to load attachments from cache: ${e.message}',
      );
      try {
        final cached = await localDataSource.getCachedAttachments(issueId);
        if (cached != null && cached.isNotEmpty) {
          logger.info(
            'Loaded ${cached.length} attachments from cache (server error fallback)',
          );
          
          // Verify local files still exist and add paths if missing
          final attachments = <AttachmentEntity>[];
          for (final json in cached) {
            final attachment = AttachmentModel.fromJson(json).toEntity();

            // If no localFilePath in cache, try to find it
            if (attachment.localFilePath == null && attachment.id != null) {
              final localPath = await localDataSource.getLocalAttachmentPath(
                issueId: issueId,
                attachmentId: attachment.id!,
                fileName: attachment.fileName,
              );
              if (localPath != null) {
                attachments.add(attachment.copyWith(localFilePath: localPath));
              } else {
                attachments.add(attachment);
              }
            } else if (attachment.localFilePath != null) {
              // Verify file still exists
              final file = File(attachment.localFilePath!);
              if (await file.exists()) {
                attachments.add(attachment);
              } else {
                // File was deleted, remove local path
                logger.warning(
                  'Local file not found: ${attachment.localFilePath}, using remote URL',
                );
                attachments.add(attachment.copyWith(localFilePath: null));
              }
            } else {
              attachments.add(attachment);
            }
          }
          return Right(attachments);
        }
      } catch (cacheError) {
        logger.warning('Failed to load attachments from cache: $cacheError');
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      logger.severe('Unexpected error in getAttachments: $e');
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Map IssueStatus enum to OpenProject status ID
  int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1;
      case IssueStatus.inProgress:
        return 2;
      case IssueStatus.onHold:
        return 3;
      case IssueStatus.closed:
        return 4;
      case IssueStatus.rejected:
        return 5;
    }
  }
}
