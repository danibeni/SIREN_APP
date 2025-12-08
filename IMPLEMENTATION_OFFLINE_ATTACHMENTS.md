# Implementación de Attachments Offline

## Resumen

Se ha implementado exitosamente el sistema de descarga y almacenamiento local de attachments para que estén disponibles cuando no hay conexión al servidor de OpenProject.

## Cambios Implementados

### 1. Dependencias Agregadas

**Archivo:** `pubspec.yaml`

Se agregaron dos nuevas dependencias:
- `path_provider: ^2.1.1` - Para acceder al directorio de caché de la aplicación
- `path: ^1.8.3` - Para manipulación de rutas de archivos

### 2. Entidades del Dominio

**Archivo:** `lib/features/issues/domain/entities/attachment_entity.dart`

- Agregado campo `localFilePath` (nullable) para almacenar la ruta al archivo local descargado
- Actualizado método `copyWith` para incluir el nuevo campo
- Actualizado `props` para comparación de igualdad

### 3. Modelos de Datos

**Archivo:** `lib/features/issues/data/models/attachment_model.dart`

- Agregado campo `localFilePath` al modelo
- Actualizado `fromJson` para parsear el campo del JSON
- Actualizado `toJson` para serializar el campo
- Actualizado `copyWith` para incluir el nuevo campo
- Actualizado `toEntity` para mapear el campo a la entidad

### 4. Data Source Local

**Archivo:** `lib/features/issues/data/datasources/issue_local_datasource.dart`

**Nuevas dependencias inyectadas:**
- `DioClient` - Para realizar las descargas HTTP
- `ServerConfigService` - Para obtener la URL del servidor

**Nuevos métodos implementados:**

#### `downloadAndCacheAttachment()`
- Descarga attachments del servidor si son ≤ 5MB
- Almacena archivos en `/cache/attachments/{issueId}/{attachmentId}_{fileName}`
- Sanitiza nombres de archivo para evitar problemas de sistema de archivos
- Verifica si el archivo ya existe antes de descargar
- Retorna la ruta local si la descarga es exitosa, `null` si falla o excede el límite de tamaño
- Usa Dio con autenticación para descargar los archivos

#### `getLocalAttachmentPath()`
- Busca la ruta de un attachment cacheado localmente
- Verifica si el archivo existe antes de retornar la ruta
- Retorna `null` si el archivo no existe

#### `clearLocalAttachments()`
- Elimina todos los archivos de attachments de una issue del directorio local
- Llamado automáticamente cuando se limpia la caché de una issue

#### `_getDio()`
- Método privado que crea una instancia de Dio configurada con:
  - URL del servidor de OpenProject
  - Autenticación (tokens OAuth2)
  - Configuración de timeouts

**Método actualizado:**

#### `clearAttachments()`
- Ahora también limpia los archivos locales además de los metadatos

### 5. Repositorio

**Archivo:** `lib/features/issues/data/repositories/issue_repository_impl.dart`

**Import agregado:** `dart:io` para verificar existencia de archivos

**Método `getIssues()` actualizado:**
- Cuando se cachea el listado de issues, ahora también se descargan los attachments
- Para cada attachment embebido:
  1. Verifica si tiene URL de descarga y ID
  2. Llama a `downloadAndCacheAttachment()` con límite de 5MB
  3. Actualiza el attachment con la ruta local si la descarga fue exitosa
  4. Guarda los attachments con sus rutas locales en el caché de metadata

**Método `getAttachments()` actualizado:**
- Cuando se cargan attachments desde el caché (offline o error de servidor):
  1. Para cada attachment cacheado:
     - Si no tiene `localFilePath` en caché, busca el archivo localmente
     - Si tiene `localFilePath`, verifica que el archivo aún exista
     - Si el archivo fue eliminado, remueve el `localFilePath`
  2. Retorna los attachments con las rutas locales actualizadas

Este flujo garantiza que:
- Los archivos se verifican antes de usarse
- Si un archivo local fue eliminado manualmente, la app no falla
- Los attachments están disponibles offline si fueron cacheados

### 6. Presentación

**Archivo:** `lib/features/issues/presentation/widgets/attachment_list_item.dart`

**Import agregado:** `dart:io` para manejo de archivos locales

**Campo agregado:** `localFilePath` (nullable)

**Método `_openAttachment()` reescrito con lógica de prioridad:**

1. **PRIORIDAD 1: Archivo Local**
   - Si existe `localFilePath`, intenta abrir el archivo local
   - Usa `Uri.file()` para crear un URI de archivo
   - Verifica que el archivo exista antes de intentar abrirlo
   - Si falla, muestra error y continúa a la siguiente opción

2. **PRIORIDAD 2: URL Remota**
   - Si no hay archivo local o falló, intenta usar `downloadUrl`
   - Si no hay URL disponible, muestra mensaje indicando que el attachment no está disponible offline

3. **Feedback al Usuario:**
   - "Error opening cached file" - Si falla al abrir archivo local
   - "Attachment not available offline. Connect to download." - Si no hay archivo local ni URL
   - "Cannot open this file type" - Si el sistema no puede abrir el tipo de archivo
   - "Error opening file" - Otros errores

**Widget `build()` actualizado:**
- Ahora muestra un ícono verde de "offline_pin" si el attachment está cacheado localmente
- El ícono "open_in_new" se muestra si hay `downloadUrl` O `localFilePath`

**Archivo:** `lib/features/issues/presentation/pages/issue_detail_page.dart`

- Actualizado `itemBuilder` de la lista de attachments para pasar `localFilePath` al widget `AttachmentListItem`

### 7. Tests

**Archivo:** `test/features/issues/data/datasources/issue_local_datasource_test.dart`

- Agregados mocks para `DioClient` y `ServerConfigService`
- Actualizados todos los tests para inyectar las nuevas dependencias

## Flujo de Funcionamiento

### Cuando el Usuario Refresca la Lista de Issues (Online):

1. Se obtiene la lista de issues del servidor
2. Para cada issue:
   - Se cachean los detalles completos
   - Se extraen los attachments embebidos
   - Para cada attachment ≤ 5MB:
     - Se descarga el archivo a `/cache/attachments/{issueId}/`
     - Se guarda la ruta local en el metadata del attachment
   - Se cachean los metadatos de attachments (incluyendo rutas locales)

### Cuando el Usuario Abre una Issue (Offline):

1. Se intenta cargar la issue del servidor
2. Si falla (NetworkFailure o ServerFailure):
   - Se cargan los detalles de la issue desde el caché local
   - Se cargan los attachments desde el caché de metadata
   - Para cada attachment:
     - Se verifica si existe la ruta local
     - Se verifica que el archivo aún exista en el sistema de archivos
     - Se actualiza el estado según corresponda

### Cuando el Usuario Abre un Attachment (Offline):

1. Si el attachment tiene `localFilePath`:
   - Se verifica que el archivo exista
   - Se intenta abrir con la aplicación predeterminada del sistema
   - Muestra icono verde de "cached" en la lista
2. Si no hay archivo local:
   - Se intenta usar el `downloadUrl` (fallará si está offline)
   - Muestra mensaje de "no disponible offline"

### Cuando una Issue se Remueve del Caché:

1. Se eliminan los metadatos de la issue
2. Se eliminan los metadatos de attachments
3. Se eliminan todos los archivos de attachments del directorio local
4. Esto ocurre automáticamente cuando la issue sale de las "3 pantallas" del caché

## Características Clave

### ✅ Límite de Tamaño
- Solo se descargan attachments ≤ 5MB
- Attachments más grandes solo guardan metadata (nombre, tipo, URL)
- Esto previene llenar el almacenamiento del dispositivo

### ✅ Descarga Eficiente
- Los archivos se descargan una sola vez durante el caché del listado
- Se verifica si el archivo ya existe antes de descargar
- No se re-descargan archivos si ya están cacheados

### ✅ Robustez
- Verifica existencia de archivos antes de usarlos
- Maneja errores de descarga sin afectar el caché de la issue
- Fallback a URL remota si el archivo local falla

### ✅ Limpieza Automática
- Los archivos se eliminan cuando la issue sale del caché
- Previene acumulación de archivos huérfanos

### ✅ Experiencia de Usuario
- Indicador visual (icono verde) de attachments cacheados
- Mensajes claros sobre disponibilidad offline
- Apertura automática con aplicación predeterminada del sistema

## Limitaciones Conocidas

1. **Límite de 5MB**: Attachments más grandes no se cachean localmente
2. **Espacio en Caché**: Limitado a ~3 pantallas de issues (150 issues)
3. **Sin Sincronización Inversa**: Los attachments agregados offline no se sincronizan automáticamente

## Pruebas Realizadas

✅ Todos los tests unitarios pasaron (142 tests)
✅ `flutter analyze` sin errores
✅ `build_runner` generó código de DI correctamente

## Archivos Modificados

1. `pubspec.yaml` - Dependencias
2. `lib/features/issues/domain/entities/attachment_entity.dart`
3. `lib/features/issues/data/models/attachment_model.dart`
4. `lib/features/issues/data/datasources/issue_local_datasource.dart`
5. `lib/features/issues/data/repositories/issue_repository_impl.dart`
6. `lib/features/issues/presentation/widgets/attachment_list_item.dart`
7. `lib/features/issues/presentation/pages/issue_detail_page.dart`
8. `test/features/issues/data/datasources/issue_local_datasource_test.dart`

## Próximos Pasos (Futuros)

- [ ] Hacer configurable el límite de tamaño de attachments (Settings)
- [ ] Implementar descarga manual para attachments > 5MB
- [ ] Agregar indicador de progreso durante la descarga masiva
- [ ] Implementar sincronización de attachments agregados offline
- [ ] Agregar opción para limpiar caché manualmente

---

**Fecha de Implementación:** Diciembre 8, 2025
**Versión:** MVP - Fase 1
**Estado:** ✅ Completado y Testeado

