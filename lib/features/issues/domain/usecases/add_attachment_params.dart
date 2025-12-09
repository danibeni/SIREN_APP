/// Parameters for adding a new attachment to an issue
///
/// Encapsulates all data needed to upload an attachment via OpenProject API
class AddAttachmentParams {
  final int issueId;
  final String filePath;
  final String fileName;
  final String? description;

  const AddAttachmentParams({
    required this.issueId,
    required this.filePath,
    required this.fileName,
    this.description,
  });
}
