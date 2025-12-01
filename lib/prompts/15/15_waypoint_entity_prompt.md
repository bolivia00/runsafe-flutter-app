# Prompt Adaptado 15 para Waypoint

> Baseado em: `15_providers_remote_datasource_and_repository_impl_prompt.md`
> Função: Gerar Remote Datasource Supabase + Repository Implementation didáticos para a entidade Waypoint.

## Parâmetros
- ENTITY: `Waypoint`
- ENTITY_PLURAL: `waypoints`
- TABLE_NAME: `waypoints`
- DEST_DIR_REMOTE: `lib/features/routes/infrastructure/remote/`
- DEST_DIR_REPO: `lib/features/routes/infrastructure/repositories/`
- DAO_IMPORT_PATH: (futuro) `package:runsafe/features/routes/data/datasources/waypoints_local_dao.dart`
- REPOSITORY_INTERFACE_IMPORT: `package:runsafe/features/routes/domain/repositories/waypoints_repository.dart`
- DTO/MAPPER: Necessário criar `WaypointModel` (latitude, longitude, timestamp) + conversão para entidade.

## Entidade (referência)
Arquivo: `lib/features/routes/domain/entities/waypoint.dart`
```dart
class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
}
```
Campos esperados na tabela Supabase:
- `latitude` (double)
- `longitude` (double)
- `timestamp` (timestamptz)
- `updated_at` (timestamptz) para sync incremental
- Possível futuro: `route_id` (relacionamento) – não incluir agora se não existir

## Objetivo dos arquivos a gerar
1. `waypoints_remote_datasource_supabase.dart`
2. `waypoints_repository_impl.dart`

## Regras (adaptadas)
### Remote Datasource
- Classe: `SupabaseWaypointsRemoteDatasource`
- Método: `fetchWaypoints({DateTime? since, int limit = 500, PageCursor? cursor})`
- Filtro incremental: `updated_at`
- Paginação: offset via cursor
- Conversão: `WaypointModel.fromJson(row)` (precisa existir)
- Logs: quantidade registros + parâmetros
- Erro: página vazia

### Repository Impl
- Classe: `WaypointsRepositoryImplRemote` implementa `WaypointsRepository`
- Last sync key: `_lastSyncKey = 'waypoints_last_sync_v1'`
- `syncFromServer`: fetch + upsert + atualizar lastSync
- `loadFromCache`: DAO lista todos
- `listFeatured`: pode definir como os 10 mais recentes (`timestamp` desc)
- `getById(String id)`: Waypoint não tem id nativo → usar timestamp ISO como id ou gerar hash latitude+longitude+timestamp
- Logs kDebugMode principais pontos

## Checklist Específico Waypoint
- Criar/garantir `WaypointModel` com parse robusto de timestamp
- Decidir identificador: `timestamp.toIso8601String()` como chave primária local
- Tratamento defensivo para timestamps inválidos

## Saída Esperada
Dois arquivos com comentários didáticos, logs e bloco final de uso.

## NÃO EXECUTAR
Somente preparar o prompt adaptado.

## Referências internas
Citar arquivos de debug (supabase_init_debug_prompt.md, supabase_rls_remediation.md) nos comentários.
