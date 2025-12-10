// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'SIREN';

  @override
  String get appSubtitle =>
      'Sistema para Gestión de Incidencias y Notificación de Ingeniería';

  @override
  String get appInitTitle => 'SIREN';

  @override
  String get appInitTagline =>
      'Sistema para Gestión de Incidencias\\ny Notificación de Ingeniería';

  @override
  String get initializing => 'Inicializando...';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsServerConfiguration => 'Configuración del servidor';

  @override
  String get settingsServerUrl => 'URL del servidor';

  @override
  String get settingsServerUrlPlaceholder => 'https://openproject.ejemplo.com';

  @override
  String get settingsNotConfigured => 'No configurado';

  @override
  String get settingsEditConfiguration => 'Editar configuración';

  @override
  String get settingsSave => 'Guardar';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get settingsLogoutDescription =>
      'Esto cerrará tu sesión y borrará los tokens de autenticación almacenados en este dispositivo.\\n\\nNota: si tu navegador guardó credenciales, podrías autenticarte automáticamente al iniciar sesión otra vez. Esto es el comportamiento esperado de OAuth2.';

  @override
  String get settingsClearConfigurationTitle => '¿Borrar configuración?';

  @override
  String get settingsClearConfigurationMessage =>
      'Esto eliminará toda la configuración del servidor. Tendrás que configurarla nuevamente para usar la aplicación.';

  @override
  String get settingsConfirm => 'Confirmar';

  @override
  String get settingsClear => 'Borrar';

  @override
  String get settingsConfigSaved => 'Configuración guardada correctamente';

  @override
  String get settingsLoggedOut => 'Sesión cerrada correctamente';

  @override
  String get settingsInfo =>
      'Los cambios en la configuración del servidor requieren reiniciar la app para aplicarse.';

  @override
  String get settingsRetry => 'Reintentar';

  @override
  String get settingsSelectType => 'Tipo de paquete de trabajo';

  @override
  String get settingsSelectTypeLabel => 'Selecciona el tipo';

  @override
  String get settingsLanguageSection => 'Idioma';

  @override
  String get settingsLanguageLabel => 'Idioma de la app';

  @override
  String get settingsLanguageUpdated => 'Idioma actualizado';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsSyncing => 'Cargando...';

  @override
  String get settingsValidationUrlRequired =>
      'La URL del servidor es obligatoria';

  @override
  String get settingsValidationUrlProtocol =>
      'La URL debe empezar con http:// o https://';

  @override
  String get settingsLogoutTitle => 'Cerrar sesión';

  @override
  String get settingsCancelAction => 'Cancelar';

  @override
  String get settingsConfirmAction => 'Confirmar';

  @override
  String get settingsClearAction => 'Borrar';

  @override
  String get settingsLogoutAction => 'Cerrar sesión';

  @override
  String get settingsServerSectionLabel => 'Configuración del servidor';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaving => 'Guardando...';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonError => 'Error';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonTryAgain => 'Intentar de nuevo';

  @override
  String get commonReload => 'Recargar';

  @override
  String get issueListTitle => 'Reporte de Incidencias';

  @override
  String get issueSearchHint => 'Buscar Incidencias...';

  @override
  String get issueFilterTitle => 'Filtrar Incidencias';

  @override
  String get issueFilterClearAll => 'Limpiar Todo';

  @override
  String get issueFilterStatus => 'Estado';

  @override
  String get issueFilterPriority => 'Prioridad';

  @override
  String get issueFilterGroup => 'Grupo/Departamento';

  @override
  String get issueFilterEquipment => 'Equipo';

  @override
  String get issueFilterSelectEquipment => 'Selecciona un equipo';

  @override
  String get issueFormEquipmentLabel => 'Equipo *';

  @override
  String get issueFilterSelectGroupFirst =>
      'Selecciona un grupo/departamento primero';

  @override
  String get issueDetailTitle => 'Detalle Incidencia';

  @override
  String get issueDetailSubject => 'ASUNTO';

  @override
  String get issueDetailSubjectRequired => 'ASUNTO *';

  @override
  String get issueDetailDescription => 'DESCRIPCIÓN';

  @override
  String get issueDetailStatusPriority => 'ESTADO Y PRIORIDAD';

  @override
  String get issueDetailStatusPriorityRequired => 'ESTADO Y PRIORIDAD *';

  @override
  String get issueDetailStatus => 'Estado';

  @override
  String get issueDetailStatusRequired => 'Estado *';

  @override
  String get issueDetailPriority => 'Prioridad';

  @override
  String get issueDetailPriorityRequired => 'Prioridad *';

  @override
  String get issueDetailAttachments => 'ADJUNTOS';

  @override
  String get issueDetailEditMode =>
      'Modo Edición - Modificación de incidencia habilitada';

  @override
  String get issueNewIssue => 'Nueva Incidencia';

  @override
  String get issueCreateIssue => 'Crear incidente';

  @override
  String get issueFormSubjectLabel => 'Asunto *';

  @override
  String get issueFormSubjectHint => 'Ingresa el asunto de la incidencia';

  @override
  String get issueFormDescriptionLabel => 'Descripción';

  @override
  String get issueFormDescriptionHint =>
      'Ingresa la descripción de la incidencia (opcional)';

  @override
  String get issueFormGroupLabel => 'Grupo/Departamento *';

  @override
  String get issueFormGroupHint => 'Selecciona un grupo';

  @override
  String get issueFormPriorityLabel => 'Prioridad *';

  @override
  String get issueFormCreateButton => 'Crear Incidencia';

  @override
  String get issueFormNoWorkPackageTypes =>
      'No hay tipos de paquete de trabajo disponibles para este proyecto';

  @override
  String get issueCreatedSuccessfully => 'Incidente creado correctamente';

  @override
  String get issueUpdatedSuccessfully => 'Incidente actualizado correctamente';

  @override
  String get issueDiscardChangesTitle => '¿Descartar cambios?';

  @override
  String get issueDiscardChangesMessage =>
      '¿Estás seguro de que quieres descartar tus cambios?';

  @override
  String get issueDiscard => 'Descartar';

  @override
  String get issueAddAttachment => 'Agregar adjunto';

  @override
  String get issueSelectFile => 'Seleccionar archivo';

  @override
  String get issueSelectFileSubtitle => 'Elige un archivo del dispositivo';

  @override
  String get issueSelectImage => 'Seleccionar imagen';

  @override
  String get issueSelectImageSubtitle => 'Elige una imagen de la galería';

  @override
  String get issueUploadingAttachment => 'Subiendo adjunto...';

  @override
  String get issueAttachmentAddedSuccessfully =>
      'Adjunto agregado correctamente';

  @override
  String get issueAttachmentFailed =>
      'Error al agregar adjunto. Por favor, inténtalo de nuevo.';

  @override
  String issueErrorSelectingFile(String error) {
    return 'Error al seleccionar archivo: $error';
  }

  @override
  String issueErrorSelectingImage(String error) {
    return 'Error al seleccionar imagen: $error';
  }

  @override
  String get issueFilePathNotAvailable =>
      'La ruta del archivo no está disponible';

  @override
  String get issueFileNotFound => 'Archivo no encontrado';

  @override
  String issueErrorProcessingFile(String error) {
    return 'Error al procesar archivo: $error';
  }

  @override
  String issueFilterFailedToLoad(String error) {
    return 'Error al cargar opciones de filtro: $error';
  }

  @override
  String get issueFilterApplyFilters => 'Aplicar filtros';

  @override
  String issueFilterFailedToLoadEquipment(String error) {
    return 'Error al cargar equipos: $error';
  }

  @override
  String get issueAttachmentCachedFileNotFound =>
      'Archivo en caché no encontrado. Intentando descargar...';

  @override
  String issueAttachmentErrorOpeningCached(String error) {
    return 'Error al abrir archivo en caché: $error';
  }

  @override
  String get issueAttachmentCannotOpenFileType =>
      'No se puede abrir este tipo de archivo';

  @override
  String issueAttachmentErrorOpeningFile(String error) {
    return 'Error al abrir archivo: $error';
  }

  @override
  String configConfigurationSaved(String url) {
    return 'Configuración guardada: $url';
  }

  @override
  String get configAuthenticationSuccessful => '¡Autenticación exitosa!';

  @override
  String get configUpdateConfiguration => 'Actualizar configuración';
}
