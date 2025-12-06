# Implementación: Filtrado por Type y Preparación para Adjuntos

## Resumen de Cambios

Se ha completado la implementación del filtrado automático por Work Package Type configurado en Settings, ordenación por fecha de modificación, y preparación para la carga de adjuntos en el listado de incidencias.

## Cambios Realizados

### 1. Filtrado Automático por Work Package Type

#### Domain Layer
- **`GetIssuesUseCase`** (`lib/features/issues/domain/usecases/get_issues_uc.dart`):
  - Añadida inyección de `GetWorkPackageTypeUseCase`
  - Obtiene automáticamente el tipo configurado en Settings
  - Pasa el tipo al repositorio para filtrar las incidencias
  - Retorna failure si no se puede obtener el tipo

- **`IssueRepository`** (`lib/features/issues/domain/repositories/issue_repository.dart`):
  - Actualizado método `getIssues` con parámetro **requerido** `workPackageType`
  - Documentación actualizada indicando que el filtro siempre se aplica

#### Data Layer
- **`IssueRepositoryImpl`** (`lib/features/issues/data/repositories/issue_repository_impl.dart`):
  - Implementada resolución de Type name a Type ID
  - Obtiene tipos disponibles de OpenProject via `getTypesByProject`
  - Busca el tipo por nombre (case-insensitive)
  - Pasa el `typeId` al data source
  - **Ordenación implementada**: Las incidencias se ordenan por `updatedAt` descendente (más reciente primero)

- **`IssueRemoteDataSource`** (`lib/features/issues/data/datasources/issue_remote_datasource.dart`):
  - Añadido parámetro `typeId` para filtrar por tipo
  - Añadidos parámetros `sortBy` y `sortDirection` para ordenación
  - Valores por defecto: `sortBy='updated_at'`, `sortDirection='desc'`

- **`IssueRemoteDataSourceImpl`** (`lib/features/issues/data/datasources/issue_remote_datasource_impl.dart`):
  - Implementado filtro de tipo en la llamada API usando sintaxis de OpenProject:
    ```dart
    'type': {
      'operator': '=',
      'values': [typeId.toString()],
    }
    ```
  - Añadido parámetro `sortBy` en queryParams: `'sortBy': '[["$sortBy","$sortDirection"]]'`
  - El filtro por tipo se aplica SIEMPRE cuando `typeId` está presente

### 2. Preparación para Carga de Adjuntos

#### Entidades
- **`IssueEntity`** (`lib/features/issues/domain/entities/issue_entity.dart`):
  - Añadido campo `attachmentCount` (int?) para mostrar número de adjuntos
  - Actualizado `copyWith` y `props` para incluir el nuevo campo

- **`IssueModel`** (`lib/features/issues/data/models/issue_model.dart`):
  - Añadido campo `attachmentCount`
  - Implementada extracción del conteo de adjuntos desde la respuesta API:
    - Intenta obtenerlo de `_links.attachments` (array)
    - Si falla, intenta desde `_embedded.attachments.elements` (array)
    - Si ambos fallan, queda como `null`
  - Actualizado `toEntity()` y `copyWith()` para incluir el nuevo campo

### 3. Tests Actualizados

- **`get_issues_uc_test.dart`**:
  - Añadido mock de `GetWorkPackageTypeUseCase`
  - Configurado para retornar "Issue" por defecto
  - Actualizado para pasar `workPackageType` en todas las llamadas
  - Añadido test para verificar que retorna failure cuando falla la obtención del tipo

- **`issue_repository_impl_test.dart`**:
  - Añadido mock de `getTypesByProject` para resolución de tipo
  - Actualizado para incluir parámetros `typeId`, `sortBy`, `sortDirection`
  - Todas las llamadas a `getIssues` ahora incluyen `workPackageType: 'Issue'`

## Comportamiento del Sistema

### Filtrado por Type
1. El usuario configura un Work Package Type en Settings (por defecto: "Issue")
2. Cuando se carga la lista de incidencias:
   - `GetIssuesUseCase` obtiene automáticamente el tipo configurado
   - El tipo se resuelve a un ID buscando en los tipos disponibles de OpenProject
   - El filtro se aplica en la llamada API a OpenProject
   - **SOLO** se obtienen work packages del tipo configurado

3. Si cambia el tipo en Settings:
   - `WorkPackageTypeCubit` emite un nuevo estado
   - `IssueListPage` escucha el cambio y recarga la lista
   - La nueva lista solo contiene work packages del nuevo tipo

### Ordenación
- Las incidencias se ordenan por fecha de modificación (`updatedAt`)
- Orden descendente: **la más recientemente modificada aparece primero**
- La ordenación se aplica tanto en la API (via `sortBy` parameter) como en el repository (sort de la lista)

### Adjuntos (Preparación MVP)
- El campo `attachmentCount` está disponible en `IssueEntity`
- Se puede usar para mostrar un indicador visual (ej: "📎 3" en el card)
- La lista de incidencias ya está preparada para mostrar cuántos adjuntos tiene cada incidencia
- **Nota**: La carga completa de adjuntos (archivos) se implementa según `WORKFLOW_STORY4_ATTACHMENTS.md`

## Verificación

✅ **Análisis de código**: Sin errores (`flutter analyze`)
✅ **Pruebas**: 107 tests pasando
✅ **Inyección de dependencias**: Regenerada correctamente

## Impacto en UI

El `IssuesListCubit` no requiere cambios porque `GetIssuesUseCase` maneja el filtrado automáticamente. Sin embargo, se recomienda:

1. **Añadir `BlocListener` para cambios de tipo** (ya implementado en workflow):
```dart
BlocListener<WorkPackageTypeCubit, WorkPackageTypeState>(
  listener: (context, typeState) {
    if (typeState is WorkPackageTypeLoaded) {
      context.read<IssuesListCubit>().loadIssues();
    }
  },
  child: // ... IssueListPage content
)
```

2. **Mostrar indicador de adjuntos** en `IssueCard`:
```dart
if (issue.attachmentCount != null && issue.attachmentCount! > 0)
  Row(
    children: [
      Icon(Icons.attach_file, size: 16),
      SizedBox(width: 4),
      Text('${issue.attachmentCount}'),
    ],
  ),
```

## Próximos Pasos

1. ✅ Implementado filtrado por tipo
2. ✅ Implementada ordenación por fecha de modificación
3. ✅ Preparado para mostrar conteo de adjuntos
4. ⏭️ Implementar carga de adjuntos completos según `WORKFLOW_STORY4_ATTACHMENTS.md`
5. ⏭️ Implementar cache local de 3 pantallas (según `WORKFLOW_STORY4_ISSUE_LISTING.md`)
6. ⏭️ Implementar cache de statuses al refrescar lista

## Commit Sugerido

```bash
git add .
git commit -m "feat(issues): implement Type filtering and sorting by modification date

- Add automatic Work Package Type filtering in GetIssuesUseCase
- Retrieve configured type from Settings and apply filter to API
- Resolve Type name to Type ID dynamically from OpenProject
- Sort issues by updatedAt (most recent first) in both API and repository
- Add attachmentCount field to IssueEntity for attachment indicators
- Extract attachment count from API response (_links or _embedded)
- Update tests to include Type filtering and new parameters
- All 107 tests passing

BREAKING CHANGE: IssueRepository.getIssues() now requires workPackageType parameter

Implements requirements from:
- WORKFLOW_STORY4_ISSUE_LISTING.md (Type filtering, sorting)
- PHASE3_TASKS_SIREN.md (Story 4 tasks)
"
```

## Notas Técnicas

### Resolución de Type ID
La resolución de Type name a ID se hace dinámicamente:
- No se hardcodean IDs de tipo
- Se obtienen los tipos disponibles de OpenProject
- Se busca por nombre (case-insensitive)
- Si falla, continúa sin filtro de tipo (mejor que fallar completamente)

### Ordenación
Se aplica doble ordenación para robustez:
1. **En API**: via parámetro `sortBy` en la query
2. **En Repository**: sort de la lista por si la API no retorna ordenada

### Conteo de Adjuntos
Se intenta obtener de dos fuentes para compatibilidad con diferentes versiones de OpenProject:
1. `_links.attachments` (array de links)
2. `_embedded.attachments.elements` (array embebido)

Si ambos fallan, `attachmentCount` queda como `null` (no hay adjuntos o no disponible).

