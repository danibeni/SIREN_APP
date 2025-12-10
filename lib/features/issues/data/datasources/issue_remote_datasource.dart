import 'package:siren_app/features/issues/domain/entities/issue_entity.dart';

/// Remote data source interface for OpenProject API communication
///
/// This interface defines the contract for remote API operations.
/// The implementation handles HTTP requests to OpenProject API v3.
abstract class IssueRemoteDataSource {
  /// Retrieve all work packages (issues) from OpenProject API
  ///
  /// Returns only issues accessible to the authenticated user
  /// (enforced by OpenProject API group-based access control)
  ///
  /// [status] - Optional filter by status ID
  /// [equipmentId] - Optional filter by project/equipment ID
  /// [priorityLevel] - Optional filter by priority
  /// [groupId] - Optional filter by group ID
  /// [typeId] - Optional filter by Work Package Type ID
  /// [offset] - Pagination offset
  /// [pageSize] - Number of items per page
  /// [sortBy] - Sort criteria (e.g., "updated_at" for modification date)
  /// [sortDirection] - Sort direction ("asc" or "desc")
  Future<List<Map<String, dynamic>>> getIssues({
    int? status,
    int? equipmentId,
    PriorityLevel? priorityLevel,
    int? groupId,
    int? typeId,
    int offset = 0,
    int pageSize = 50,
    String sortBy = 'updated_at',
    String sortDirection = 'desc',
  });

  /// Retrieve a single work package by ID
  ///
  /// Must capture lockVersion for subsequent updates
  Future<Map<String, dynamic>> getIssueById(int id);

  /// Create a new work package (issue)
  ///
  /// Uses two-step flow:
  /// 1. Validation: POST /api/v3/projects/{id}/work_packages/form
  /// 2. Execution: POST /api/v3/work_packages
  ///
  /// Returns the created work package with all fields including ID and lockVersion
  Future<Map<String, dynamic>> createIssue({
    required String subject,
    String? description,
    required int equipment, // project ID
    required int group, // group ID
    required PriorityLevel priorityLevel,
  });

  /// Update an existing work package
  ///
  /// Requires lockVersion for optimistic locking
  /// Updates: Subject, Description, Priority Level, Status
  /// Note: Group and Equipment are read-only and must not be included
  Future<Map<String, dynamic>> updateIssue({
    required int id,
    required int lockVersion,
    String? subject,
    String? description,
    PriorityLevel? priorityLevel,
    IssueStatus? status,
  });

  /// Add attachment to a work package
  ///
  /// Uploads photo/document for issue resolution
  /// Returns attachment metadata including id, fileName, fileSize, etc.
  Future<Map<String, dynamic>> addAttachment({
    required int issueId,
    required String filePath,
    required String fileName,
    String? description,
  });

  /// Retrieve all groups accessible to the authenticated user
  ///
  /// Used for Group selection in issue creation
  Future<List<Map<String, dynamic>>> getGroups();

  /// Retrieve projects (equipment) available for a specific group
  ///
  /// Filters projects by group membership
  Future<List<Map<String, dynamic>>> getProjectsByGroup(int groupId);

  /// Retrieve all statuses (global)
  ///
  /// Used for Status dropdown
  Future<List<Map<String, dynamic>>> getStatuses();

  /// Retrieve types for a specific project
  ///
  /// Types are project-specific and required for issue creation
  Future<List<Map<String, dynamic>>> getTypesByProject(int projectId);

  /// Retrieve all priorities from OpenProject
  ///
  /// Used for mapping PriorityLevel to actual OpenProject priority IDs
  Future<List<Map<String, dynamic>>> getPriorities();

  /// Retrieve available work package types
  ///
  /// Used for Settings type selection
  Future<List<Map<String, dynamic>>> getTypes();

  /// Retrieve all attachments for a work package
  ///
  /// Returns attachments in collection format with _embedded.elements
  /// Includes metadata: fileName, fileSize, contentType, createdAt
  /// HATEOAS links: downloadLocation, delete (if permitted), author
  Future<List<Map<String, dynamic>>> getAttachments(int issueId);

  /// Get work package form to retrieve available statuses for the specific type
  ///
  /// Calls POST /api/v3/work_packages/{id}/form to get schema with available
  /// statuses based on the work package's type and current state.
  /// Returns form response with schema containing available status options.
  Future<Map<String, dynamic>> getWorkPackageForm({
    required int workPackageId,
    required int lockVersion,
  });
}
