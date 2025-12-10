import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/config/server_config_service.dart';
import 'package:siren_app/core/error/exceptions.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/core/network/dio_client.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'issue_remote_datasource.dart';

/// Implementation of IssueRemoteDataSource for OpenProject API v3
///
/// This class handles all HTTP communication with the OpenProject API.
/// It uses Dio for HTTP requests and follows HATEOAS principles.
@LazySingleton(as: IssueRemoteDataSource)
class IssueRemoteDataSourceImpl implements IssueRemoteDataSource {
  final DioClient _dioClient;
  final ServerConfigService _serverConfigService;
  final Logger logger;

  IssueRemoteDataSourceImpl({
    required DioClient dioClient,
    required ServerConfigService serverConfigService,
    required this.logger,
  }) : _dioClient = dioClient,
       _serverConfigService = serverConfigService;

  /// Get configured Dio instance with server baseUrl
  Future<Dio> _getDio() async {
    final serverUrlResult = await _serverConfigService.getServerUrl();
    return serverUrlResult.fold(
      (failure) {
        logger.severe('Failed to get server URL: ${failure.message}');
        throw ServerFailure(
          'Server URL not configured. Please configure the server in settings.',
        );
      },
      (serverUrl) {
        if (serverUrl == null || serverUrl.isEmpty) {
          throw ServerFailure(
            'Server URL not configured. Please configure the server in settings.',
          );
        }
        return _dioClient.createDio(serverUrl);
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getIssues({
    List<int>? statusIds,
    List<int>? priorityIds,
    int? equipmentId,
    int? groupId,
    int? typeId,
    String? searchTerms,
    int offset = 0,
    int pageSize = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
  }) async {
    try {
      final dio = await _getDio();
      final filterList = <Map<String, dynamic>>[];

      // CRITICAL: Always filter by Work Package Type if provided
      if (typeId != null) {
        filterList.add({
          'type': {
            'operator': '=',
            'values': [typeId.toString()],
          },
        });
      }

      // Multi-select status filter
      if (statusIds != null && statusIds.isNotEmpty) {
        filterList.add({
          'status': {
            'operator': '=',
            'values': statusIds.map((id) => id.toString()).toList(),
          },
        });
      }

      // Multi-select priority filter
      if (priorityIds != null && priorityIds.isNotEmpty) {
        filterList.add({
          'priority': {
            'operator': '=',
            'values': priorityIds.map((id) => id.toString()).toList(),
          },
        });
      }

      // Single-select equipment/project filter
      if (equipmentId != null) {
        filterList.add({
          'project': {
            'operator': '=',
            'values': [equipmentId.toString()],
          },
        });
      }

      // Group filter: resolve projects for the selected group, then filter by project
      // OpenProject does not expose a direct group filter for work packages, so we
      // scope the query to the projects (equipment) that belong to the group.
      if (groupId != null) {
        try {
          final projects = await getProjectsByGroup(groupId);
          final projectIds = projects
              .map((p) => p['id'] as int?)
              .whereType<int>()
              .toList();
          if (projectIds.isNotEmpty) {
            filterList.add({
              'project': {
                'operator': '=',
                'values': projectIds.map((id) => id.toString()).toList(),
              },
            });
          } else {
            logger.info(
              'Group $groupId has no projects; skipping project filter for group',
            );
          }
        } catch (e) {
          logger.warning(
            'Failed to resolve projects for group $groupId, proceeding without group filter: $e',
          );
        }
      }

      // Text search using subjectOrId filter (searches in Subject and ID)
      // OpenProject API v3 uses subjectOrId with ** operator for contains search
      if (searchTerms != null && searchTerms.trim().isNotEmpty) {
        final searchTerm = searchTerms.trim();
        filterList.add({
          'subjectOrId': {
            'operator': '**',
            'values': [searchTerm],
          },
        });
        // Note: OpenProject subjectOrId searches in subject and ID
        // For description search, we would need a separate filter if supported
        // Currently, OpenProject API v3 primarily supports subject/ID search
        // Description search may require full-text search capabilities
      }

      final queryParams = <String, dynamic>{
        'offset': offset,
        'pageSize': pageSize,
      };

      // Add filters as JSON array (OpenProject expects array of filter objects)
      if (filterList.isNotEmpty) {
        queryParams['filters'] = jsonEncode(filterList);
      }

      // Add sorting (OpenProject expects JSON array format)
      queryParams['sortBy'] = jsonEncode([
        [sortBy, sortDirection],
      ]);

      // Include status and priority to get their colors dynamically
      queryParams['include'] = 'status,priority';

      final response = await dio.get(
        '/work_packages',
        queryParameters: queryParams,
      );

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      logger.severe('Error fetching issues: $e');
      // Check for network/server inaccessibility errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == null) {
        // Use enhanced message from interceptor if available
        final errorMessage =
            e.message?.contains('server') == true ||
                e.message?.contains('unreachable') == true ||
                e.message?.contains('Wi-Fi') == true
            ? e.message!
            : 'Cannot connect to OpenProject server. Please verify the server is accessible via Wi-Fi.';
        throw NetworkFailure(errorMessage);
      }
      final errorMessage = _extractErrorMessage(e);
      throw ServerFailure('Failed to fetch issues: $errorMessage');
    } catch (e) {
      logger.severe('Error fetching issues: $e');
      if (e is NetworkFailure || e is ServerFailure) {
        rethrow;
      }
      throw ServerFailure('Failed to fetch issues: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getIssueById(int id) async {
    try {
      final dio = await _getDio();
      final response = await dio.get(
        '/work_packages/$id',
        queryParameters: const {'include': 'status,priority'},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('Error fetching issue $id: $e');
      // Check for network/server inaccessibility errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.response?.statusCode == null) {
        // Use enhanced message from interceptor if available
        final errorMessage =
            e.message?.contains('server') == true ||
                e.message?.contains('unreachable') == true ||
                e.message?.contains('Wi-Fi') == true
            ? e.message!
            : 'Cannot connect to OpenProject server. Please verify the server is accessible via Wi-Fi.';
        throw NetworkFailure(errorMessage);
      }
      final errorMessage = _extractErrorMessage(e);
      throw ServerFailure('Failed to fetch issue: $errorMessage');
    } catch (e) {
      logger.severe('Error fetching issue $id: $e');
      if (e is NetworkFailure || e is ServerFailure) {
        rethrow;
      }
      throw ServerFailure('Failed to fetch issue: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> createIssue({
    required String subject,
    String? description,
    required int equipment,
    required int group,
    required PriorityLevel priorityLevel,
  }) async {
    try {
      final dio = await _getDio();

      // Step 0: Get available types for the project
      final types = await getTypesByProject(equipment);
      if (types.isEmpty) {
        throw ServerFailure('No work package types available for this project');
      }
      final typeId = types.first['id'] as int;
      final typeHref =
          types.first['_links']?['self']?['href'] as String? ??
          '/api/v3/types/$typeId';

      // Get priority href dynamically from server
      final priorityHref = await _getPriorityHref(priorityLevel);
      logger.info('Using priority href: $priorityHref for $priorityLevel');

      // Step 1: Validate payload using form endpoint
      final formPayload = {
        '_links': {
          'project': {'href': '/api/v3/projects/$equipment'},
          'type': {'href': typeHref},
          'priority': {'href': priorityHref},
        },
        'subject': subject,
        if (description != null)
          'description': {'format': 'markdown', 'raw': description},
      };

      Map<String, dynamic> validatedPayload;

      try {
        final formResponse = await dio.post(
          '/projects/$equipment/work_packages/form',
          data: formPayload,
        );
        final formData = formResponse.data as Map<String, dynamic>;

        // OpenProject form endpoint returns the validated payload in _embedded.payload
        final embedded = formData['_embedded'] as Map<String, dynamic>?;
        validatedPayload = embedded?['payload'] as Map<String, dynamic>? ?? {};

        // Log the payload for debugging
        logger.info('Form validated payload: $validatedPayload');

        // Check for validation errors in the form response
        final validationErrors =
            embedded?['validationErrors'] as Map<String, dynamic>?;
        if (validationErrors != null && validationErrors.isNotEmpty) {
          final errorMessages = validationErrors.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');
          throw ServerFailure('Validation errors: $errorMessages');
        }
      } on DioException catch (e) {
        logger.severe(
          'Form validation error: ${e.response?.data ?? e.message}',
        );
        final errorMessage = _extractErrorMessage(e);
        throw ServerFailure('Form validation failed: $errorMessage');
      }

      // Ensure subject is in the payload (OpenProject may not preserve it)
      if (validatedPayload['subject'] == null ||
          (validatedPayload['subject'] as String).isEmpty) {
        validatedPayload['subject'] = subject;
      }

      // Ensure priority is preserved in the payload
      // OpenProject may use default priority instead of the selected one
      final validatedLinks =
          validatedPayload['_links'] as Map<String, dynamic>? ?? {};
      final validatedPriorityHref =
          validatedLinks['priority']?['href'] as String?;

      // If priority is missing or different, restore it
      if (validatedPriorityHref != priorityHref) {
        validatedLinks['priority'] = {'href': priorityHref};
        validatedPayload['_links'] = validatedLinks;
        logger.info(
          'Priority restored in payload: $priorityHref (was: $validatedPriorityHref)',
        );
      }

      // Log final payload before creation
      logger.info('Final payload _links: ${validatedPayload['_links']}');

      // Step 2: Create work package with validated payload
      try {
        logger.info('Creating work package with payload: $validatedPayload');
        final createResponse = await dio.post(
          '/work_packages',
          data: validatedPayload,
        );

        return createResponse.data as Map<String, dynamic>;
      } on DioException catch (e) {
        logger.severe(
          'Create work package error: ${e.response?.data ?? e.message}',
        );
        final errorMessage = _extractErrorMessage(e);
        throw ServerFailure('Failed to create issue: $errorMessage');
      }
    } catch (e) {
      if (e is ServerFailure) {
        rethrow;
      }
      logger.severe('Error creating issue: $e');
      throw ServerFailure('Failed to create issue: ${e.toString()}');
    }
  }

  /// Extract error message from DioException response
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        // OpenProject API error format
        final error = data['_embedded']?['errors'] as List<dynamic>?;
        if (error != null && error.isNotEmpty) {
          final firstError = error.first as Map<String, dynamic>?;
          return firstError?['message'] as String? ??
              firstError?.toString() ??
              'Unknown error';
        }
        // Alternative error format
        final message = data['message'] as String?;
        if (message != null) return message;
      }
      return data.toString();
    }
    return e.message ?? 'Unknown error';
  }

  @override
  Future<Map<String, dynamic>> updateIssue({
    required int id,
    required int lockVersion,
    String? subject,
    String? description,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
    String? statusHref,
  }) async {
    try {
      final dio = await _getDio();
      final payload = <String, dynamic>{'lockVersion': lockVersion};
      final links = <String, dynamic>{};

      if (subject != null) {
        payload['subject'] = subject;
      }

      if (description != null) {
        payload['description'] = {'format': 'markdown', 'raw': description};
      }

      if (priorityLevel != null) {
        links['priority'] = {
          'href': '/api/v3/priorities/${_mapPriorityToId(priorityLevel)}',
        };
      }

      if (statusHref != null) {
        links['status'] = {'href': statusHref};
      } else if (status != null) {
        links['status'] = {'href': '/api/v3/statuses/${_mapStatusToId(status)}'};
      }

      if (links.isNotEmpty) {
        payload['_links'] = links;
      }

      final response = await dio.patch(
        '/work_packages/$id',
        data: payload,
        queryParameters: const {'include': 'status,priority'},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('Error updating issue $id: $e');

      // Handle specific error cases
      if (e.response?.statusCode == 409) {
        // Conflict - lockVersion mismatch (optimistic locking)
        throw ConflictException('Issue has been modified by another user');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Issue not found');
      } else if (e.response?.statusCode == 422) {
        // Unprocessable Entity - validation error
        final errorMessage = _extractErrorMessage(e);
        throw ValidationException('Validation failed: $errorMessage');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Network errors - use enhanced message from interceptor if available
        // The interceptor already provides user-friendly messages about server inaccessibility
        final errorMessage =
            e.message?.contains('server') == true ||
                e.message?.contains('unreachable') == true ||
                e.message?.contains('Wi-Fi') == true
            ? e.message!
            : 'Cannot connect to OpenProject server. Please verify the server is accessible via Wi-Fi.';
        throw NetworkException(errorMessage);
      } else if (e.response?.statusCode == null) {
        // No response received - likely server unreachable
        final errorMessage =
            e.message?.contains('server') == true ||
                e.message?.contains('unreachable') == true ||
                e.message?.contains('Wi-Fi') == true
            ? e.message!
            : 'OpenProject server unreachable. Please check your Wi-Fi connection and verify the server is accessible.';
        throw NetworkException(errorMessage);
      } else {
        final errorMessage = _extractErrorMessage(e);
        throw ServerException('Failed to update issue: $errorMessage');
      }
    } catch (e) {
      // Re-throw if already an exception
      if (e is AppException) {
        rethrow;
      }
      logger.severe('Unexpected error updating issue $id: $e');
      throw ServerException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      final dio = await _getDio();

      // Verify file exists before attempting upload
      final file = File(filePath);
      if (!await file.exists()) {
        throw ServerException('File not found: $filePath');
      }

      logger.info(
        'Uploading attachment: $fileName (${await file.length()} bytes) to issue $issueId',
      );

      // Build multipart form data according to OpenProject API v3
      // OpenProject requires two parts:
      // 1. 'metadata' part with JSON containing fileName (required) and description (optional)
      // 2. 'file' part with the actual file binary data
      final metadataJson = {
        'fileName': fileName,
        if (description != null) 'description': description,
      };

      final formData = FormData.fromMap({
        'metadata': MultipartFile.fromString(
          jsonEncode(metadataJson),
          filename: null,
          contentType: null, // Let Dio set Content-Type automatically
        ),
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await dio.post(
        '/work_packages/$issueId/attachments',
        data: formData,
      );

      logger.info('Attachment uploaded successfully: ${response.statusCode}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe(
        'DioException adding attachment to issue $issueId: '
        '${e.response?.statusCode} - ${e.response?.statusMessage}',
      );
      logger.severe('Response data: ${e.response?.data}');
      logger.severe('Request path: ${e.requestOptions.path}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException('Network error: ${e.message}');
      } else {
        final errorMessage = _extractErrorMessage(e);
        throw ServerException('Failed to add attachment: $errorMessage');
      }
    } catch (e) {
      // Re-throw if already an exception
      if (e is AppException) {
        rethrow;
      }
      logger.severe('Unexpected error adding attachment to issue $issueId: $e');
      throw ServerException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/groups');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching groups: $e');
      throw ServerFailure('Failed to fetch groups: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProjectsByGroup(int groupId) async {
    try {
      final dio = await _getDio();
      // OpenProject API automatically filters projects by user permissions
      final response = await dio.get('/projects');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      // Filter projects that have createWorkPackage link (user can create issues)
      final projects = elements.cast<Map<String, dynamic>>().where((project) {
        final links = project['_links'] as Map<String, dynamic>?;
        return links?.containsKey('createWorkPackage') ?? false;
      }).toList();

      return projects;
    } catch (e) {
      logger.severe('Error fetching projects for group $groupId: $e');
      throw ServerFailure('Failed to fetch projects: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/statuses');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching statuses: $e');
      throw ServerFailure('Failed to fetch statuses: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTypesByProject(int projectId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/projects/$projectId/types');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching types for project $projectId: $e');
      throw ServerFailure('Failed to fetch types: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPriorities() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/priorities');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching priorities: $e');
      throw ServerFailure('Failed to fetch priorities: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTypes() async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/types');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching types: $e');
      throw ServerFailure('Failed to fetch types: ${e.toString()}');
    }
  }

  /// Map PriorityLevel enum to OpenProject priority href dynamically
  ///
  /// Fetches priorities from server and maps by name
  Future<String> _getPriorityHref(PriorityLevel priority) async {
    final priorities = await getPriorities();

    // Map PriorityLevel to expected OpenProject priority names
    final priorityName = switch (priority) {
      PriorityLevel.low => 'Low',
      PriorityLevel.normal => 'Normal',
      PriorityLevel.high => 'High',
      PriorityLevel.immediate => 'Immediate',
    };

    // Find matching priority by name (case-insensitive)
    for (final p in priorities) {
      final name = p['name'] as String? ?? '';
      if (name.toLowerCase() == priorityName.toLowerCase()) {
        final href = p['_links']?['self']?['href'] as String?;
        if (href != null) {
          logger.info('Found priority "$name" with href: $href');
          return href;
        }
        // Fallback to constructing href from id
        final id = p['id'] as int?;
        if (id != null) {
          logger.info('Found priority "$name" with id: $id');
          return '/api/v3/priorities/$id';
        }
      }
    }

    // Log available priorities for debugging
    final availablePriorities = priorities
        .map((p) => '${p['name']} (id: ${p['id']})')
        .join(', ');
    logger.warning(
      'Priority "$priorityName" not found. Available: $availablePriorities',
    );

    // Fallback to hardcoded mapping if not found
    final fallbackId = switch (priority) {
      PriorityLevel.low => 7,
      PriorityLevel.normal => 8,
      PriorityLevel.high => 9,
      PriorityLevel.immediate => 10,
    };
    return '/api/v3/priorities/$fallbackId';
  }

  /// Map PriorityLevel enum to OpenProject priority ID (fallback)
  int _mapPriorityToId(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return 7;
      case PriorityLevel.normal:
        return 8;
      case PriorityLevel.high:
        return 9;
      case PriorityLevel.immediate:
        return 10;
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

  @override
  Future<List<Map<String, dynamic>>> getAttachments(int issueId) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/work_packages/$issueId/attachments');

      logger.info('Raw attachments response: ${response.data}');

      // Parse collection response format
      final responseData = response.data as Map<String, dynamic>;
      final embedded = responseData['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      logger.info(
        'Retrieved ${elements.length} attachments for issue $issueId',
      );

      // Log each attachment for debugging
      for (var element in elements) {
        logger.info('Attachment data: $element');
      }

      return elements.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      logger.severe('Error fetching attachments for issue $issueId: $e');

      // Handle specific error codes
      if (e.response?.statusCode == 404) {
        throw ServerFailure('Work package not found or access denied');
      } else if (e.response?.statusCode == 401) {
        throw NetworkFailure('Authentication required');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Connection timeout');
      } else {
        throw ServerFailure('Failed to fetch attachments: ${e.toString()}');
      }
    } catch (e) {
      logger.severe('Unexpected error fetching attachments: $e');
      throw ServerFailure('Failed to fetch attachments: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getWorkPackageForm({
    required int workPackageId,
    required int lockVersion,
  }) async {
    try {
      final dio = await _getDio();

      // Call form endpoint to get schema with available statuses
      // The form endpoint returns information about available transitions
      // and valid values for the work package's current type and state
      final response = await dio.post(
        '/work_packages/$workPackageId/form',
        data: {'lockVersion': lockVersion},
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.severe('Error fetching form for work package $workPackageId: $e');

      if (e.response?.statusCode == 404) {
        throw ServerFailure('Work package not found');
      } else if (e.response?.statusCode == 409) {
        throw ConflictException('Work package has been modified');
      } else if (e.response?.statusCode == 401) {
        throw NetworkFailure('Authentication required');
      } else {
        final errorMessage = _extractErrorMessage(e);
        throw ServerFailure('Failed to fetch form: $errorMessage');
      }
    } catch (e) {
      logger.severe('Unexpected error fetching form: $e');
      throw ServerFailure('Failed to fetch form: ${e.toString()}');
    }
  }
}
