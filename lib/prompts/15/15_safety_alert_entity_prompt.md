# Prompt Adaptado 15 para SafetyAlert

> Baseado em: `15_providers_remote_datasource_and_repository_impl_prompt.md`
> Função: Gerar Remote Datasource Supabase + Repository Implementation didáticos para a entidade SafetyAlert.

## Parâmetros
- ENTITY: `SafetyAlert`
- ENTITY_PLURAL: `safety_alerts`
- TABLE_NAME: `safety_alerts`
- DEST_DIR_REMOTE: `lib/features/alerts/infrastructure/remote/`
- DEST_DIR_REPO: `lib/features/alerts/infrastructure/repositories/`
- DAO_IMPORT_PATH: (Implementar futuramente) ex.: `package:runsafe/features/alerts/data/datasources/safety_alerts_local_dao.dart`
- REPOSITORY_INTERFACE_IMPORT: `package:runsafe/features/alerts/domain/repositories/safety_alerts_repository.dart`
- DTO/MAPPER: Necessário definir um `SafetyAlertModel` (não existe ainda) com `fromJson/toJson` e conversão para entidade.

## Entidade (referência)
Arquivo: `lib/features/alerts/domain/entities/safety_alert.dart`
```dart
enum AlertType { pothole, noLighting, suspiciousActivity, other }
class SafetyAlert {
  final String id;
  final String description;
  final AlertType type;
  final DateTime timestamp;
  final int severity; // 1..5
}
```
Campos esperados na tabela Supabase:
- `id` (uuid/string)
- `description` (text)
- `type` (text ou enum string)
- `timestamp` (timestamptz) -> mapear para DateTime
- `severity` (int)
- `updated_at` (timestamptz) para sync incremental

## Objetivo dos arquivos a gerar
1. `safety_alerts_remote_datasource_supabase.dart`
2. `safety_alerts_repository_impl.dart`

## Regras (adaptadas)
### Remote Datasource
- Classe: `SupabaseSafetyAlertsRemoteDatasource`
- Método: `fetchSafetyAlerts({DateTime? since, int limit = 500, PageCursor? cursor})`
- Filtro incremental: `updated_at`
- Paginação: offset via `cursor.value`
- Conversão: usar `SafetyAlertModel.fromJson(row)` (precisará existir)
- Retorno: `RemotePage<SafetyAlertModel>`
- Logs: quantidade registros, parâmetros utilizados, erros
- Erro: página vazia
- Comentário introdutório + bloco final

### Repository Impl
- Classe: `SafetyAlertsRepositoryImplRemote` implementa `SafetyAlertsRepository`
- Last sync key: `_lastSyncKey = 'safety_alerts_last_sync_v1'`
- `syncFromServer`: usa remote datasource, upsert via DAO local (`save`/`upsertAll` a ser criado), atualiza lastSync
- `loadFromCache`: lista completa via DAO
- `listFeatured`: filtra `severity >= 4`
- `getById`: retornar alerta específico
- Logs kDebugMode em sync

## Checklist Específico SafetyAlert
- Criar/garantir `SafetyAlertModel` com robustez para `type` (enum -> string) e datas
- Parse seguro de `timestamp` e `updated_at`
- Evitar erro ao converter severidade (padronizar int)

## Saída Esperada
Dois arquivos com comentários didáticos + logs + bloco final de uso.

## NÃO EXECUTAR
Apenas preparar prompt adaptado.

## Referências internas
Citar arquivos de debug (supabase_init_debug_prompt.md, supabase_rls_remediation.md) nos comentários.
