// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SIREN';

  @override
  String get appSubtitle =>
      'System for Issue Reporting and Engineering Notification';

  @override
  String get appInitTitle => 'SIREN';

  @override
  String get appInitTagline =>
      'System for Issue Reporting\\nand Engineering Notification';

  @override
  String get initializing => 'Initializing...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsServerConfiguration => 'Server Configuration';

  @override
  String get settingsServerUrl => 'Server URL';

  @override
  String get settingsServerUrlPlaceholder => 'https://openproject.example.com';

  @override
  String get settingsNotConfigured => 'Not configured';

  @override
  String get settingsEditConfiguration => 'Edit Configuration';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsLogoutDescription =>
      'This will log you out and clear stored authentication tokens from this device.\\n\\nNote: If your browser has saved credentials, you may be automatically re-authenticated when you log in again. This is expected OAuth2 behavior.';

  @override
  String get settingsClearConfigurationTitle => 'Clear Configuration?';

  @override
  String get settingsClearConfigurationMessage =>
      'This will remove all server configuration. You will need to reconfigure the app to use it again.';

  @override
  String get settingsConfirm => 'Confirm';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsConfigSaved => 'Configuration saved successfully';

  @override
  String get settingsLoggedOut => 'Logged out successfully';

  @override
  String get settingsInfo =>
      'Changes to server configuration will require restarting the app to take effect.';

  @override
  String get settingsRetry => 'Retry';

  @override
  String get settingsSelectType => 'Work Package Type';

  @override
  String get settingsSelectTypeLabel => 'Select type';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageLabel => 'App language';

  @override
  String get settingsLanguageUpdated => 'Language updated';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsSyncing => 'Loading...';

  @override
  String get settingsValidationUrlRequired => 'Server URL is required';

  @override
  String get settingsValidationUrlProtocol =>
      'URL must start with http:// or https://';

  @override
  String get settingsLogoutTitle => 'Logout';

  @override
  String get settingsCancelAction => 'Cancel';

  @override
  String get settingsConfirmAction => 'Confirm';

  @override
  String get settingsClearAction => 'Clear';

  @override
  String get settingsLogoutAction => 'Logout';

  @override
  String get settingsServerSectionLabel => 'Server Configuration';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get commonReload => 'Reload';

  @override
  String get issueListTitle => 'Issue Reporting';

  @override
  String get issueSearchHint => 'Search issues...';

  @override
  String get issueFilterTitle => 'Filter Issues';

  @override
  String get issueFilterClearAll => 'Clear All';

  @override
  String get issueFilterStatus => 'Status';

  @override
  String get issueFilterPriority => 'Priority';

  @override
  String get issueFilterGroup => 'Group';

  @override
  String get issueFilterEquipment => 'Equipment';

  @override
  String get issueFilterSelectEquipment => 'Select equipment';

  @override
  String get issueFormEquipmentLabel => 'Equipment *';

  @override
  String get issueFilterSelectGroupFirst => 'Select a group first';

  @override
  String get issueDetailTitle => 'Issue Details';

  @override
  String get issueDetailSubject => 'SUBJECT';

  @override
  String get issueDetailSubjectRequired => 'SUBJECT *';

  @override
  String get issueDetailDescription => 'DESCRIPTION';

  @override
  String get issueDetailStatusPriority => 'STATUS & PRIORITY';

  @override
  String get issueDetailStatusPriorityRequired => 'STATUS & PRIORITY *';

  @override
  String get issueDetailStatus => 'Status';

  @override
  String get issueDetailStatusRequired => 'Status *';

  @override
  String get issueDetailPriority => 'Priority';

  @override
  String get issueDetailPriorityRequired => 'Priority *';

  @override
  String get issueDetailAttachments => 'ATTACHMENTS';

  @override
  String get issueDetailEditMode => 'Edit Mode - Modify Issues enabled';

  @override
  String get issueNewIssue => 'New Issue';

  @override
  String get issueCreateIssue => 'Create Issue';

  @override
  String get issueFormSubjectLabel => 'Subject *';

  @override
  String get issueFormSubjectHint => 'Enter issue subject';

  @override
  String get issueFormDescriptionLabel => 'Description';

  @override
  String get issueFormDescriptionHint => 'Enter issue description (optional)';

  @override
  String get issueFormGroupLabel => 'Group *';

  @override
  String get issueFormGroupHint => 'Select a group';

  @override
  String get issueFormPriorityLabel => 'Priority *';

  @override
  String get issueFormCreateButton => 'Create Issue';

  @override
  String get issueFormNoWorkPackageTypes =>
      'No work package types available for this project';

  @override
  String get issueCreatedSuccessfully => 'Issue created successfully';

  @override
  String get issueUpdatedSuccessfully => 'Issue updated successfully';

  @override
  String get issueDiscardChangesTitle => 'Discard Changes?';

  @override
  String get issueDiscardChangesMessage =>
      'Are you sure you want to discard your changes?';

  @override
  String get issueDiscard => 'Discard';

  @override
  String get issueAddAttachment => 'Add Attachment';

  @override
  String get issueSelectFile => 'Select File';

  @override
  String get issueSelectFileSubtitle => 'Choose a file from device';

  @override
  String get issueSelectImage => 'Select Image';

  @override
  String get issueSelectImageSubtitle => 'Choose an image from gallery';

  @override
  String get issueUploadingAttachment => 'Uploading attachment...';

  @override
  String get issueAttachmentAddedSuccessfully =>
      'Attachment added successfully';

  @override
  String get issueAttachmentFailed =>
      'Failed to add attachment. Please try again.';

  @override
  String issueErrorSelectingFile(String error) {
    return 'Error selecting file: $error';
  }

  @override
  String issueErrorSelectingImage(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get issueFilePathNotAvailable => 'File path is not available';

  @override
  String get issueFileNotFound => 'File not found';

  @override
  String issueErrorProcessingFile(String error) {
    return 'Error processing file: $error';
  }

  @override
  String issueFilterFailedToLoad(String error) {
    return 'Failed to load filter options: $error';
  }

  @override
  String get issueFilterApplyFilters => 'Apply Filters';

  @override
  String issueFilterFailedToLoadEquipment(String error) {
    return 'Failed to load equipment: $error';
  }

  @override
  String get issueAttachmentCachedFileNotFound =>
      'Cached file not found. Trying to download...';

  @override
  String issueAttachmentErrorOpeningCached(String error) {
    return 'Error opening cached file: $error';
  }

  @override
  String get issueAttachmentCannotOpenFileType => 'Cannot open this file type';

  @override
  String issueAttachmentErrorOpeningFile(String error) {
    return 'Error opening file: $error';
  }

  @override
  String configConfigurationSaved(String url) {
    return 'Configuration saved: $url';
  }

  @override
  String get configAuthenticationSuccessful => 'Authentication successful!';

  @override
  String get configUpdateConfiguration => 'Update Configuration';
}
