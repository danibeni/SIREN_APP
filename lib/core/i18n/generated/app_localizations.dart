import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SIREN'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System for Issue Reporting and Engineering Notification'**
  String get appSubtitle;

  /// No description provided for @appInitTitle.
  ///
  /// In en, this message translates to:
  /// **'SIREN'**
  String get appInitTitle;

  /// No description provided for @appInitTagline.
  ///
  /// In en, this message translates to:
  /// **'System for Issue Reporting\\nand Engineering Notification'**
  String get appInitTagline;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsServerConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get settingsServerConfiguration;

  /// No description provided for @settingsServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get settingsServerUrl;

  /// No description provided for @settingsServerUrlPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://openproject.example.com'**
  String get settingsServerUrlPlaceholder;

  /// No description provided for @settingsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsNotConfigured;

  /// No description provided for @settingsEditConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Edit Configuration'**
  String get settingsEditConfiguration;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutDescription.
  ///
  /// In en, this message translates to:
  /// **'This will log you out and clear stored authentication tokens from this device.\\n\\nNote: If your browser has saved credentials, you may be automatically re-authenticated when you log in again. This is expected OAuth2 behavior.'**
  String get settingsLogoutDescription;

  /// No description provided for @settingsClearConfigurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Configuration?'**
  String get settingsClearConfigurationTitle;

  /// No description provided for @settingsClearConfigurationMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all server configuration. You will need to reconfigure the app to use it again.'**
  String get settingsClearConfigurationMessage;

  /// No description provided for @settingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirm;

  /// No description provided for @settingsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// No description provided for @settingsConfigSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved successfully'**
  String get settingsConfigSaved;

  /// No description provided for @settingsLoggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get settingsLoggedOut;

  /// No description provided for @settingsInfo.
  ///
  /// In en, this message translates to:
  /// **'Changes to server configuration will require restarting the app to take effect.'**
  String get settingsInfo;

  /// No description provided for @settingsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get settingsRetry;

  /// No description provided for @settingsSelectType.
  ///
  /// In en, this message translates to:
  /// **'Work Package Type'**
  String get settingsSelectType;

  /// No description provided for @settingsSelectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get settingsSelectTypeLabel;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get settingsLanguageUpdated;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsSyncing.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get settingsSyncing;

  /// No description provided for @settingsValidationUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Server URL is required'**
  String get settingsValidationUrlRequired;

  /// No description provided for @settingsValidationUrlProtocol.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get settingsValidationUrlProtocol;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancelAction;

  /// No description provided for @settingsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirmAction;

  /// No description provided for @settingsClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClearAction;

  /// No description provided for @settingsLogoutAction.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogoutAction;

  /// No description provided for @settingsServerSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Server Configuration'**
  String get settingsServerSectionLabel;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @commonReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get commonReload;

  /// No description provided for @issueListTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Reporting'**
  String get issueListTitle;

  /// No description provided for @issueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search issues...'**
  String get issueSearchHint;

  /// No description provided for @issueFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Issues'**
  String get issueFilterTitle;

  /// No description provided for @issueFilterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get issueFilterClearAll;

  /// No description provided for @issueFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get issueFilterStatus;

  /// No description provided for @issueFilterPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get issueFilterPriority;

  /// No description provided for @issueFilterGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get issueFilterGroup;

  /// No description provided for @issueFilterEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get issueFilterEquipment;

  /// No description provided for @issueFilterSelectEquipment.
  ///
  /// In en, this message translates to:
  /// **'Select equipment'**
  String get issueFilterSelectEquipment;

  /// No description provided for @issueFormEquipmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Equipment *'**
  String get issueFormEquipmentLabel;

  /// No description provided for @issueFilterSelectGroupFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a group first'**
  String get issueFilterSelectGroupFirst;

  /// No description provided for @issueDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue Details'**
  String get issueDetailTitle;

  /// No description provided for @issueDetailSubject.
  ///
  /// In en, this message translates to:
  /// **'SUBJECT'**
  String get issueDetailSubject;

  /// No description provided for @issueDetailSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'SUBJECT *'**
  String get issueDetailSubjectRequired;

  /// No description provided for @issueDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get issueDetailDescription;

  /// No description provided for @issueDetailStatusPriority.
  ///
  /// In en, this message translates to:
  /// **'STATUS & PRIORITY'**
  String get issueDetailStatusPriority;

  /// No description provided for @issueDetailStatusPriorityRequired.
  ///
  /// In en, this message translates to:
  /// **'STATUS & PRIORITY *'**
  String get issueDetailStatusPriorityRequired;

  /// No description provided for @issueDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get issueDetailStatus;

  /// No description provided for @issueDetailStatusRequired.
  ///
  /// In en, this message translates to:
  /// **'Status *'**
  String get issueDetailStatusRequired;

  /// No description provided for @issueDetailPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get issueDetailPriority;

  /// No description provided for @issueDetailPriorityRequired.
  ///
  /// In en, this message translates to:
  /// **'Priority *'**
  String get issueDetailPriorityRequired;

  /// No description provided for @issueDetailAttachments.
  ///
  /// In en, this message translates to:
  /// **'ATTACHMENTS'**
  String get issueDetailAttachments;

  /// No description provided for @issueDetailEditMode.
  ///
  /// In en, this message translates to:
  /// **'Edit Mode - Modify Issues enabled'**
  String get issueDetailEditMode;

  /// No description provided for @issueNewIssue.
  ///
  /// In en, this message translates to:
  /// **'New Issue'**
  String get issueNewIssue;

  /// No description provided for @issueCreateIssue.
  ///
  /// In en, this message translates to:
  /// **'Create Issue'**
  String get issueCreateIssue;

  /// No description provided for @issueFormSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject *'**
  String get issueFormSubjectLabel;

  /// No description provided for @issueFormSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Enter issue subject'**
  String get issueFormSubjectHint;

  /// No description provided for @issueFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get issueFormDescriptionLabel;

  /// No description provided for @issueFormDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter issue description (optional)'**
  String get issueFormDescriptionHint;

  /// No description provided for @issueFormGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group *'**
  String get issueFormGroupLabel;

  /// No description provided for @issueFormGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Select a group'**
  String get issueFormGroupHint;

  /// No description provided for @issueFormPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority *'**
  String get issueFormPriorityLabel;

  /// No description provided for @issueFormCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Issue'**
  String get issueFormCreateButton;

  /// No description provided for @issueFormNoWorkPackageTypes.
  ///
  /// In en, this message translates to:
  /// **'No work package types available for this project'**
  String get issueFormNoWorkPackageTypes;

  /// No description provided for @issueCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Issue created successfully'**
  String get issueCreatedSuccessfully;

  /// No description provided for @issueUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Issue updated successfully'**
  String get issueUpdatedSuccessfully;

  /// No description provided for @issueDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get issueDiscardChangesTitle;

  /// No description provided for @issueDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to discard your changes?'**
  String get issueDiscardChangesMessage;

  /// No description provided for @issueDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get issueDiscard;

  /// No description provided for @issueAddAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get issueAddAttachment;

  /// No description provided for @issueSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get issueSelectFile;

  /// No description provided for @issueSelectFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a file from device'**
  String get issueSelectFileSubtitle;

  /// No description provided for @issueSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get issueSelectImage;

  /// No description provided for @issueSelectImageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an image from gallery'**
  String get issueSelectImageSubtitle;

  /// No description provided for @issueUploadingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Uploading attachment...'**
  String get issueUploadingAttachment;

  /// No description provided for @issueAttachmentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Attachment added successfully'**
  String get issueAttachmentAddedSuccessfully;

  /// No description provided for @issueAttachmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add attachment. Please try again.'**
  String get issueAttachmentFailed;

  /// No description provided for @issueErrorSelectingFile.
  ///
  /// In en, this message translates to:
  /// **'Error selecting file: {error}'**
  String issueErrorSelectingFile(String error);

  /// No description provided for @issueErrorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String issueErrorSelectingImage(String error);

  /// No description provided for @issueFilePathNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'File path is not available'**
  String get issueFilePathNotAvailable;

  /// No description provided for @issueFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get issueFileNotFound;

  /// No description provided for @issueErrorProcessingFile.
  ///
  /// In en, this message translates to:
  /// **'Error processing file: {error}'**
  String issueErrorProcessingFile(String error);

  /// No description provided for @issueFilterFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load filter options: {error}'**
  String issueFilterFailedToLoad(String error);

  /// No description provided for @issueFilterApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get issueFilterApplyFilters;

  /// No description provided for @issueFilterFailedToLoadEquipment.
  ///
  /// In en, this message translates to:
  /// **'Failed to load equipment: {error}'**
  String issueFilterFailedToLoadEquipment(String error);

  /// No description provided for @issueAttachmentCachedFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cached file not found. Trying to download...'**
  String get issueAttachmentCachedFileNotFound;

  /// No description provided for @issueAttachmentErrorOpeningCached.
  ///
  /// In en, this message translates to:
  /// **'Error opening cached file: {error}'**
  String issueAttachmentErrorOpeningCached(String error);

  /// No description provided for @issueAttachmentCannotOpenFileType.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this file type'**
  String get issueAttachmentCannotOpenFileType;

  /// No description provided for @issueAttachmentErrorOpeningFile.
  ///
  /// In en, this message translates to:
  /// **'Error opening file: {error}'**
  String issueAttachmentErrorOpeningFile(String error);

  /// No description provided for @configConfigurationSaved.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved: {url}'**
  String configConfigurationSaved(String url);

  /// No description provided for @configAuthenticationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Authentication successful!'**
  String get configAuthenticationSuccessful;

  /// No description provided for @configUpdateConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Update Configuration'**
  String get configUpdateConfiguration;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
