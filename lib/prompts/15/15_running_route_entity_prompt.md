# Prompt Adaptado 15 para RunningRoute

> Baseado em: `15_providers_remote_datasource_and_repository_impl_prompt.md`
> Função: Gerar Remote Datasource Supabase + Repository Implementation didáticos para a entidade RunningRoute.

## Parâmetros
- ENTITY: `RunningRoute`
- ENTITY_PLURAL: `running_routes`
- TABLE_NAME: `running_routes`
- DEST_DIR_REMOTE: `lib/features/routes/infrastructure/remote/`
- DEST_DIR_REPO: `lib/features/routes/infrastructure/repositories/`
- DAO_IMPORT_PATH: (futuro) `package:runsafe/features/routes/data/datasources/running_routes_local_dao.dart`
- REPOSITORY_INTERFACE_IMPORT: `package:runsafe/features/routes/domain/repositories/running_routes_repository.dart`
- DTO/MAPPER: Necessário criar `RunningRouteModel` + `WaypointModel` (lista aninhada) para conversão robusta.

## Entidade (referência)
Arquivo: `lib/features/routes/domain/entities/running_route.dart`
```dart
class RunningRoute {
  final String id;
  final String name;
  final List<Waypoint> waypoints;
  double get totalDistanceInKm => waypoints.length * 0.01; // simplificação
}
```
Dependência: `Waypoint` (latitude, longitude, timestamp).

Campos esperados na tabela Supabase:
- `id` (uuid/string)
- `name` (text)
- `waypoints` (jsonb lista de objetos {lat, lng, timestamp})
- `updated_at` (timestamptz) para sync incremental

## Objetivo dos arquivos a gerar
1. `running_routes_remote_datasource_supabase.dart`
2. `running_routes_repository_impl.dart`

## Regras (adaptadas)
### Remote Datasource
- Classe: `SupabaseRunningRoutesRemoteDatasource`
- Método: `fetchRunningRoutes({DateTime? since, int limit = 200, PageCursor? cursor})` (limite menor por payload maior)
- Filtro incremental: `updated_at`
- Paginação: offset via cursor
- Conversão: `RunningRouteModel.fromJson(row)` incluindo parse da lista de waypoints
- Retorno: `RemotePage<RunningRouteModel>`
- Logs: quantidade de rotas, quantidade média de waypoints, erros
- Erro: página vazia

### Repository Impl
- Classe: `RunningRoutesRepositoryImplRemote` implementa `RunningRoutesRepository`
- Last sync key: `_lastSyncKey = 'running_routes_last_sync_v1'`
- `syncFromServer`: fetch rotas; cada rota convertida para entidade; salvar via DAO (precisará ter `saveRoute(route)` e talvez limpar/merge de waypoints)
- `loadFromCache`: lista completa
- `listFeatured`: rotas com `waypoints.length >= 5` (exemplo) ou heurística futura
- `getById(String id)`
- Logs kDebugMode: início sync, quantidade rotas, total waypoints agregados, timestamp atualização

## Checklist Específico RunningRoute
- Criar `RunningRouteModel` com lista de `WaypointModel` interna
- Garantir serialização robusta de lista JSON (null / vazia)
- Parse defensivo `updated_at`
- Evitar duplicação de rotas (upsert pelo id)

## Saída Esperada
Dois arquivos com comentários didáticos + logs + bloco de uso.

## NÃO EXECUTAR
Apenas gerar prompt adaptado agora.

## Referências internas
Citar arquivos de debug (supabase_init_debug_prompt.md, supabase_rls_remediation.md) nos comentários.
