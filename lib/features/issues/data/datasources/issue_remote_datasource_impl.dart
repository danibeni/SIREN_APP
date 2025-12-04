import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/config/server_config_service.dart';
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
  })  : _dioClient = dioClient,
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
    int? status,
    int? equipmentId,
    PriorityLevel? priorityLevel,
    int? groupId,
    int offset = 0,
    int pageSize = 50,
  }) async {
    try {
      final dio = await _getDio();
      final filters = <Map<String, dynamic>>[];

      if (status != null) {
        filters.add({
          'status': {
            'operator': '=',
            'values': [status.toString()],
          },
        });
      }

      if (equipmentId != null) {
        filters.add({
          'project': {
            'operator': '=',
            'values': [equipmentId.toString()],
          },
        });
      }

      if (priorityLevel != null) {
        filters.add({
          'priority': {
            'operator': '=',
            'values': [_mapPriorityToId(priorityLevel).toString()],
          },
        });
      }

      if (groupId != null) {
        // Filter by group - OpenProject filters by project membership
      }

      final queryParams = <String, dynamic>{
        'offset': offset,
        'pageSize': pageSize,
      };

      if (filters.isNotEmpty) {
        queryParams['filters'] = filters;
      }

      final response = await dio.get(
        '/work_packages',
        queryParameters: queryParams,
      );

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching issues: $e');
      throw ServerFailure('Failed to fetch issues: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getIssueById(int id) async {
    try {
      final dio = await _getDio();
      final response = await dio.get('/work_packages/$id');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.severe('Error fetching issue $id: $e');
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
        throw ServerFailure(
          'No work package types available for this project',
        );
      }
      final typeId = types.first['id'] as int;
      final typeHref = types.first['_links']?['self']?['href'] as String? ??
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
  }) async {
    try {
      final dio = await _getDio();
      final payload = <String, dynamic>{'lockVersion': lockVersion};

      if (subject != null) {
        payload['subject'] = subject;
      }

      if (description != null) {
        payload['description'] = {'format': 'markdown', 'raw': description};
      }

      if (priorityLevel != null) {
        payload['_links'] = {
          'priority': {
            'href': '/api/v3/priorities/${_mapPriorityToId(priorityLevel)}',
          },
        };
      }

      if (status != null) {
        payload['_links'] = {
          ...(payload['_links'] as Map<String, dynamic>? ?? {}),
          'status': {'href': '/api/v3/statuses/${_mapStatusToId(status)}'},
        };
      }

      final response = await dio.patch('/work_packages/$id', data: payload);

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.severe('Error updating issue $id: $e');
      throw ServerFailure('Failed to update issue: ${e.toString()}');
    }
  }

  @override
  Future<void> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    try {
      final dio = await _getDio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (description != null) 'description': description,
      });

      await dio.post('/work_packages/$issueId/attachments', data: formData);
    } catch (e) {
      logger.severe('Error adding attachment to issue $issueId: $e');
      throw ServerFailure('Failed to add attachment: ${e.toString()}');
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
      case IssueStatus.closed:
        return 3;
    }
  }
}
