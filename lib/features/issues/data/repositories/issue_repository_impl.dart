import 'package:dartz/dartz.dart';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/exceptions.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/network/connectivity_service.dart';
import 'package:siren_app/features/issues/domain/entities/attachment_entity.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'package:siren_app/features/issues/domain/entities/priority_entity.dart';
import 'package:siren_app/features/issues/domain/entities/status_entity.dart';
import 'package:siren_app/features/issues/domain/repositories/issue_repository.dart';
import '../datasources/issue_local_datasource.dart';
import '../datasources/issue_remote_datasource.dart';
import '../models/attachment_model.dart';
import '../models/issue_model.dart';
import '../models/status_model.dart';

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
  final ConnectivityService connectivityService;
  final Logger logger;

  IssueRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.serverConfigService,
    required this.connectivityService,
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
    List<int>? statusIds,
    List<int>? priorityIds,
    int? equipmentId,
    int? groupId,
    String? searchTerms,
    required String workPackageType,
  }) async {
    try {
      // Resolve Work Package Type name to ID
      // Get all available types from OpenProject (global types, not project-specific)
      int? typeId;
      bool typeResolutionFailed = false;
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
        // If type resolution fails due to network error, try to use cache
        if (e is NetworkFailure ||
            e.toString().contains('connection') ||
            e.toString().contains('Network')) {
          logger.warning(
            'Failed to resolve Work Package Type due to network error, will try cache: ${e.toString()}',
          );
          typeResolutionFailed = true;
          // Continue to try loading from cache
        } else {
          // For other errors (e.g., type not found), return failure
          return Left(
            ServerFailure(
              'Failed to resolve Work Package Type: ${e.toString()}',
            ),
          );
        }
      }

      List<Map<String, dynamic>> responseList;

      // If type resolution failed due to network, skip server fetch and go to cache
      if (typeResolutionFailed) {
        logger.info(
          'Skipping server fetch due to type resolution failure, loading from cache',
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
      } else {
        try {
          // Try to fetch from server with filters
          responseList = await remoteDataSource.getIssues(
            statusIds: statusIds,
            priorityIds: priorityIds,
            equipmentId: equipmentId,
            groupId: groupId,
            typeId: typeId,
            searchTerms: searchTerms,
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
                      if (attachment.downloadUrl != null &&
                          attachment.id != null) {
                        final localPath = await localDataSource
                            .downloadAndCacheAttachment(
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
                logger.warning(
                  'Failed to cache details for issue $issueId: $e',
                );
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
      }

      // Convert each map to entity
      final entities = responseList
          .map((map) => IssueModel.fromJson(map).toEntity())
          .toList();

      // Replace entities with pending local modifications
      await _applyPendingModifications(entities);

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

          // Replace entities with pending local modifications
          await _applyPendingModifications(entities);

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
    // Check connectivity
    final isOnline = await connectivityService.isConnected();

    if (isOnline) {
      // Online: Update immediately on server
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
        final entity = model.toEntity();

        // Update local cache with server response
        await localDataSource.cacheIssueDetails(id, responseMap);

        return Right(entity);
      } on ConflictException catch (e) {
        return Left(ConflictFailure(e.message));
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        logger.severe('Unexpected error updating issue: $e');
        return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
      }
    } else {
      // Offline: Save locally
      try {
        // Get current issue from cache
        final cachedIssueJson = await localDataSource.getCachedIssueDetails(id);
        if (cachedIssueJson == null) {
          return const Left(NotFoundFailure('Issue not found in cache'));
        }

        final cachedModel = IssueModel.fromJson(cachedIssueJson);

        // Create updated issue model with local modifications
        final updatedModel = cachedModel.copyWith(
          subject: subject ?? cachedModel.subject,
          description: description ?? cachedModel.description,
          priorityLevel: priorityLevel ?? cachedModel.priorityLevel,
          status: status ?? cachedModel.status,
          lockVersion: lockVersion,
          hasPendingSync: true,
        );

        // Prepare JSON for local storage (maintain OpenProject API structure)
        final modifiedJson = Map<String, dynamic>.from(cachedIssueJson);

        // Update subject if provided
        if (subject != null) {
          modifiedJson['subject'] = subject;
        }

        // Update description if provided
        if (description != null) {
          modifiedJson['description'] = {
            'format': 'markdown',
            'raw': description,
          };
        }

        // Update priority in _links if provided
        if (priorityLevel != null) {
          final links = modifiedJson['_links'] as Map<String, dynamic>? ?? {};
          // Keep existing priority link structure, just mark that it changed
          links['priority'] = links['priority'] ?? {};
          modifiedJson['_links'] = links;
        }

        // Update status in _links if provided
        if (status != null) {
          final links = modifiedJson['_links'] as Map<String, dynamic>? ?? {};
          // Keep existing status link structure, just mark that it changed
          links['status'] = links['status'] ?? {};
          modifiedJson['_links'] = links;
        }

        // Update lockVersion
        modifiedJson['lockVersion'] = lockVersion;

        // Save locally with pending sync status
        await localDataSource.saveLocalModifications(modifiedJson);

        // Return entity with hasPendingSync = true
        final entity = updatedModel.toEntity();
        return Right(entity.copyWith(hasPendingSync: true));
      } catch (e) {
        logger.severe('Unexpected error saving local modifications: $e');
        return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, AttachmentEntity>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      final responseMap = await remoteDataSource.addAttachment(
        issueId: issueId,
        filePath: filePath,
        fileName: fileName,
        description: description,
      );

      final model = AttachmentModel.fromJson(responseMap);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      logger.severe('Unexpected error adding attachment: $e');
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

  @override
  Future<Either<Failure, IssueEntity>> syncIssue(int issueId) async {
    try {
      // Get issue with pending modifications
      final pendingIssueJson = await localDataSource.getIssueWithPendingSync(
        issueId,
      );

      if (pendingIssueJson == null) {
        return const Left(
          NotFoundFailure('No pending modifications found for this issue'),
        );
      }

      final pendingModel = IssueModel.fromJson(pendingIssueJson);

      // Upload changes to server
      final responseMap = await remoteDataSource.updateIssue(
        id: issueId,
        lockVersion: pendingModel.lockVersion,
        subject: pendingModel.subject,
        description: pendingModel.description,
        priorityLevel: pendingModel.priorityLevel,
        status: pendingModel.status,
      );

      final updatedModel = IssueModel.fromJson(responseMap);

      // Clear pending sync status
      await localDataSource.clearPendingSync(issueId);

      // Update cache with server response
      await localDataSource.cacheIssueDetails(issueId, responseMap);

      logger.info('Successfully synchronized issue $issueId');
      return Right(updatedModel.toEntity());
    } on ConflictException catch (e) {
      return Left(ConflictFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      logger.severe('Unexpected error synchronizing issue: $e');
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, IssueEntity>> discardLocalChanges(int issueId) async {
    try {
      // Get original server version from cache
      final cachedIssueJson = await localDataSource.getCachedIssueDetails(
        issueId,
      );

      if (cachedIssueJson == null) {
        return const Left(NotFoundFailure('Issue not found in cache'));
      }

      // Clear pending sync status
      await localDataSource.clearPendingSync(issueId);

      final model = IssueModel.fromJson(cachedIssueJson);
      final cleanEntity = model.toEntity().copyWith(hasPendingSync: false);

      logger.info('Successfully discarded local changes for issue $issueId');
      return Right(cleanEntity);
    } catch (e) {
      logger.severe('Unexpected error discarding local changes: $e');
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Map IssueStatus enum to OpenProject status ID
  /// Apply pending local modifications to the entities list
  ///
  /// Replaces entities in the list with their locally modified versions
  /// if they have pending sync status
  Future<void> _applyPendingModifications(List<IssueEntity> entities) async {
    try {
      // Get list of issue IDs with pending modifications
      final pendingIds = await localDataSource.getIssuesWithPendingSync();

      if (pendingIds.isEmpty) {
        return; // No pending modifications
      }

      logger.info(
        'Applying pending modifications for ${pendingIds.length} issues',
      );

      // For each pending issue, replace the entity with the modified version
      for (final issueId in pendingIds) {
        final pendingJson = await localDataSource.getIssueWithPendingSync(
          issueId,
        );
        if (pendingJson != null) {
          // Convert to entity
          final modifiedEntity = IssueModel.fromJson(pendingJson).toEntity();

          // Find and replace the entity in the list
          final index = entities.indexWhere((e) => e.id == issueId);
          if (index != -1) {
            entities[index] = modifiedEntity;
            logger.info('Replaced issue $issueId with pending modifications');
          } else {
            // If issue not in list, add it (might be a new offline-created issue)
            entities.add(modifiedEntity);
            logger.info('Added pending issue $issueId to list');
          }
        }
      }
    } catch (e) {
      logger.warning('Failed to apply pending modifications: $e');
      // Don't fail the whole operation, just log the warning
    }
  }

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

  @override
  Future<Either<Failure, List<PriorityEntity>>> getPriorities() async {
    try {
      final prioritiesJson = await remoteDataSource.getPriorities();
      final priorities = prioritiesJson.map((json) {
        final id = json['id'] as int;
        final name = json['name'] as String? ?? '';
        final href = json['_links']?['self']?['href'] as String?;

        // Extract color from API response
        String? colorHex;
        final color = json['color'];
        if (color != null) {
          if (color is String) {
            colorHex = color.startsWith('#') ? color : '#$color';
          } else if (color is Map<String, dynamic>) {
            colorHex =
                color['hexcode'] as String? ??
                color['hexCode'] as String? ??
                color['hex_code'] as String?;
            if (colorHex != null && !colorHex.startsWith('#')) {
              colorHex = '#$colorHex';
            }
          }
        }

        // Map name to PriorityLevel enum
        final priorityLevel = _mapPriorityNameToEnum(name);

        return PriorityEntity(
          id: id,
          name: name,
          href: href,
          colorHex: colorHex,
          priorityLevel: priorityLevel,
        );
      }).toList();

      return Right(priorities);
    } on ServerFailure catch (e) {
      return Left(e);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (e) {
      logger.severe('Unexpected error getting priorities: $e');
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Map priority name from API to PriorityLevel enum
  PriorityLevel _mapPriorityNameToEnum(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('low')) {
      return PriorityLevel.low;
    } else if (lowerName.contains('normal') || lowerName.contains('medium')) {
      return PriorityLevel.normal;
    } else if (lowerName.contains('high')) {
      return PriorityLevel.high;
    } else if (lowerName.contains('immediate') ||
        lowerName.contains('critical')) {
      return PriorityLevel.immediate;
    }
    // Default to normal if name doesn't match
    return PriorityLevel.normal;
  }

  @override
  Future<Either<Failure, List<StatusEntity>>> getAvailableStatusesForIssue({
    required int workPackageId,
    required int lockVersion,
  }) async {
    try {
      // Get form endpoint to retrieve schema with available statuses
      final formResponse = await remoteDataSource.getWorkPackageForm(
        workPackageId: workPackageId,
        lockVersion: lockVersion,
      );

      logger.info(
        'Form response structure for work package $workPackageId: ${formResponse.keys}',
      );

      // Try to extract available statuses from schema
      // The schema may contain status options based on workflow rules
      final embedded = formResponse['_embedded'] as Map<String, dynamic>?;
      logger.info('Embedded keys: ${embedded?.keys}');

      final schema = embedded?['schema'] as Map<String, dynamic>?;
      logger.info('Schema keys: ${schema?.keys}');

      // Check if schema has status field with available options
      final statusSchema = schema?['status'] as Map<String, dynamic>?;
      logger.info(
        'Status schema structure: ${statusSchema?.keys}, availableValues: ${statusSchema?['availableValues']}, allowedValues: ${statusSchema?['allowedValues']}, values: ${statusSchema?['values']}',
      );

      // OpenProject schema may have availableValues or allowedValues or values
      // for status field indicating which statuses are allowed for this type
      final availableValues =
          statusSchema?['availableValues'] as List<dynamic>? ??
          statusSchema?['allowedValues'] as List<dynamic>? ??
          statusSchema?['values'] as List<dynamic>?;

      // Also check for options object that might contain availableValues
      final options = statusSchema?['options'] as Map<String, dynamic>?;
      final optionsValues =
          options?['availableValues'] as List<dynamic>? ??
          options?['allowedValues'] as List<dynamic>? ??
          options?['values'] as List<dynamic>?;

      final allAvailableValues = availableValues ?? optionsValues;

      if (allAvailableValues != null && allAvailableValues.isNotEmpty) {
        logger.info(
          'Found ${allAvailableValues.length} available status values in schema',
        );

        // Extract status IDs from available values
        // Each value may be a href string or an object with href/id
        final statusIds = <int>[];
        final statusHrefs = <String>[];

        for (final value in allAvailableValues) {
          if (value is Map<String, dynamic>) {
            final href = value['href'] as String?;
            if (href != null) {
              statusHrefs.add(href);
              // Extract ID from href (e.g., /api/v3/statuses/1 -> 1)
              final idMatch = RegExp(r'/statuses/(\d+)').firstMatch(href);
              if (idMatch != null) {
                final id = int.tryParse(idMatch.group(1)!);
                if (id != null) {
                  statusIds.add(id);
                  logger.info('Extracted status ID $id from href: $href');
                }
              }
            } else {
              final id = value['id'] as int?;
              if (id != null) {
                statusIds.add(id);
                logger.info('Extracted status ID $id from value object');
              }
            }
          } else if (value is String) {
            // Value is a href string
            statusHrefs.add(value);
            final idMatch = RegExp(r'/statuses/(\d+)').firstMatch(value);
            if (idMatch != null) {
              final id = int.tryParse(idMatch.group(1)!);
              if (id != null) {
                statusIds.add(id);
                logger.info('Extracted status ID $id from href string: $value');
              }
            }
          }
        }

        // Get all statuses and filter by available IDs
        if (statusIds.isNotEmpty) {
          logger.info(
            'Filtering statuses by IDs: $statusIds for work package $workPackageId',
          );
          final allStatusesJson = await remoteDataSource.getStatuses();
          final filteredStatuses = allStatusesJson
              .where((status) => statusIds.contains(status['id'] as int?))
              .map((json) => StatusModel.fromJson(json).toEntity())
              .toList();

          logger.info(
            'Filtered ${filteredStatuses.length} statuses from schema (IDs: ${filteredStatuses.map((s) => s.id).toList()}) for work package $workPackageId',
          );
          return Right(filteredStatuses);
        } else {
          logger.warning(
            'Found availableValues in schema but could not extract status IDs',
          );
        }
      }

      // Fallback: If schema doesn't provide status options, return all statuses
      // This maintains current behavior but logs a warning
      logger.warning(
        'Schema does not contain status options for work package $workPackageId, using all statuses. Schema structure: ${schema?.toString()}',
      );

      final allStatusesJson = await remoteDataSource.getStatuses();
      final allStatuses = allStatusesJson
          .map((json) => StatusModel.fromJson(json).toEntity())
          .toList();

      logger.info(
        'Returning all ${allStatuses.length} statuses (fallback) for work package $workPackageId',
      );
      return Right(allStatuses);
    } on ServerFailure catch (e) {
      // If form endpoint fails, fallback to all statuses
      logger.warning(
        'Failed to get form for work package $workPackageId: ${e.message}, using all statuses',
      );
      try {
        final allStatusesJson = await remoteDataSource.getStatuses();
        final allStatuses = allStatusesJson
            .map((json) => StatusModel.fromJson(json).toEntity())
            .toList();
        return Right(allStatuses);
      } catch (fallbackError) {
        return Left(ServerFailure(e.message));
      }
    } on NetworkFailure catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      logger.severe('Unexpected error getting available statuses: $e');
      return Left(UnexpectedFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
