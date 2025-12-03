import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:siren_app/core/error/failures.dart';
import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';
import 'issue_remote_datasource.dart';

/// Implementation of IssueRemoteDataSource for OpenProject API v3
/// 
/// This class handles all HTTP communication with the OpenProject API.
/// It uses Dio for HTTP requests and follows HATEOAS principles.
class IssueRemoteDataSourceImpl implements IssueRemoteDataSource {
  final Dio dio;
  final Logger logger;

  IssueRemoteDataSourceImpl({
    required this.dio,
    required this.logger,
  });

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
        // Map PriorityLevel enum to OpenProject priority IDs
        // TODO: Map priority levels to actual OpenProject priority IDs
        filters.add({
          'priority': {
            'operator': '=',
            'values': [_mapPriorityToId(priorityLevel).toString()],
          },
        });
      }

      if (groupId != null) {
        // Filter by group - this may require additional API calls
        // OpenProject filters work packages by project, and projects are associated with groups
        // TODO: Implement group filtering logic
      }

      final queryParams = <String, dynamic>{
        'offset': offset,
        'pageSize': pageSize,
      };

      if (filters.isNotEmpty) {
        queryParams['filters'] = filters;
      }

      // Route is relative to base URL (/api/v3) configured in DioClient
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
      // Route is relative to base URL (/api/v3) configured in DioClient
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
      // Step 1: Validate payload using form endpoint
      // Route is relative to base URL (/api/v3) configured in DioClient
      final formResponse = await dio.post(
        '/projects/$equipment/work_packages/form',
        data: {
          '_links': {
            // HATEOAS links must use full paths as per OpenProject API specification
            'project': {'href': '/api/v3/projects/$equipment'},
            'type': {'href': '/api/v3/types/1'}, // TODO: Get actual type ID from project
            'priority': {'href': '/api/v3/priorities/${_mapPriorityToId(priorityLevel)}'},
          },
          'subject': subject,
          if (description != null) 'description': {
            'format': 'markdown',
            'raw': description,
          },
        },
      );

      // Step 2: Create work package with validated payload
      // Route is relative to base URL (/api/v3) configured in DioClient
      final createResponse = await dio.post(
        '/work_packages',
        data: formResponse.data,
      );

      return createResponse.data as Map<String, dynamic>;
    } catch (e) {
      logger.severe('Error creating issue: $e');
      throw ServerFailure('Failed to create issue: ${e.toString()}');
    }
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
      final payload = <String, dynamic>{
        'lockVersion': lockVersion,
      };

      if (subject != null) {
        payload['subject'] = subject;
      }

      if (description != null) {
        payload['description'] = {
          'format': 'markdown',
          'raw': description,
        };
      }

      if (priorityLevel != null) {
        payload['_links'] = {
          // HATEOAS links must use full paths as per OpenProject API specification
          'priority': {'href': '/api/v3/priorities/${_mapPriorityToId(priorityLevel)}'},
        };
      }

      if (status != null) {
        // TODO: Map IssueStatus to OpenProject status ID
        payload['_links'] = {
          ...(payload['_links'] as Map<String, dynamic>? ?? {}),
          // HATEOAS links must use full paths as per OpenProject API specification
          'status': {'href': '/api/v3/statuses/${_mapStatusToId(status)}'},
        };
      }

      // Route is relative to base URL (/api/v3) configured in DioClient
      final response = await dio.patch(
        '/work_packages/$id',
        data: payload,
      );

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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (description != null) 'description': description,
      });

      // Route is relative to base URL (/api/v3) configured in DioClient
      await dio.post(
        '/work_packages/$issueId/attachments',
        data: formData,
      );
    } catch (e) {
      logger.severe('Error adding attachment to issue $issueId: $e');
      throw ServerFailure('Failed to add attachment: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      // Route is relative to base URL (/api/v3) configured in DioClient
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
      // OpenProject API: Get projects where the user has access
      // Filter by group membership through user's group associations
      // Route is relative to base URL (/api/v3) configured in DioClient
      final response = await dio.get(
        '/projects',
        queryParameters: {
          'filters': [
            {
              'is_member': {
                'operator': '=',
                'values': ['t'],
              },
            },
          ],
        },
      );

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      // Filter projects that have createWorkPackage link (user can create issues)
      final projects = elements
          .cast<Map<String, dynamic>>()
          .where((project) {
            final links = project['_links'] as Map<String, dynamic>?;
            return links?.containsKey('createWorkPackage') ?? false;
          })
          .toList();

      return projects;
    } catch (e) {
      logger.severe('Error fetching projects for group $groupId: $e');
      throw ServerFailure('Failed to fetch projects: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStatuses() async {
    try {
      // Route is relative to base URL (/api/v3) configured in DioClient
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
      // Route is relative to base URL (/api/v3) configured in DioClient
      final response = await dio.get('/projects/$projectId/types');

      final embedded = response.data['_embedded'] as Map<String, dynamic>?;
      final elements = embedded?['elements'] as List<dynamic>? ?? [];

      return elements.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.severe('Error fetching types for project $projectId: $e');
      throw ServerFailure('Failed to fetch types: ${e.toString()}');
    }
  }

  /// Map PriorityLevel enum to OpenProject priority ID
  /// 
  /// TODO: This should be fetched from API and cached
  int _mapPriorityToId(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return 1; // TODO: Get actual ID from API
      case PriorityLevel.normal:
        return 2; // TODO: Get actual ID from API
      case PriorityLevel.high:
        return 3; // TODO: Get actual ID from API
      case PriorityLevel.immediate:
        return 4; // TODO: Get actual ID from API
    }
  }

  /// Map IssueStatus enum to OpenProject status ID
  /// 
  /// TODO: This should be fetched from API and cached
  int _mapStatusToId(IssueStatus status) {
    switch (status) {
      case IssueStatus.newStatus:
        return 1; // TODO: Get actual ID from API
      case IssueStatus.inProgress:
        return 2; // TODO: Get actual ID from API
      case IssueStatus.closed:
        return 3; // TODO: Get actual ID from API
    }
  }
}

