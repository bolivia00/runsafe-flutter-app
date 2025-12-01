# Prompt Adaptado 15 para WeeklyGoal

> Baseado em: `15_providers_remote_datasource_and_repository_impl_prompt.md`
> Função: Gerar Remote Datasource Supabase + Repository Implementation didáticos para a entidade WeeklyGoal.

## Parâmetros
- ENTITY: `WeeklyGoal`
- ENTITY_PLURAL: `weekly_goals`
- TABLE_NAME: `weekly_goals` (padrão)
- DEST_DIR_REMOTE: `lib/features/goals/infrastructure/remote/`
- DEST_DIR_REPO: `lib/features/goals/infrastructure/repositories/`
- DAO_IMPORT_PATH: `package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart`
- REPOSITORY_INTERFACE_IMPORT: `package:runsafe/features/goals/domain/repositories/weekly_goals_repository.dart`
- DTO/MAPPER: Usaremos `WeeklyGoalModel` como DTO (já existe) e o próprio model faz conversão.

## Entidade (referência)
Arquivo: `lib/features/goals/domain/entities/weekly_goal.dart`
```dart
class WeeklyGoal {
  final String id;
  final String userId;
  final double targetKm;
  double currentKm;
  // progressPercentage (getter)
}
```
Campos relevantes para persistência/sync:
- `id` (String, UUID)
- `user_id` (String) -> mapear para `userId`
- `target_km` (double)
- `current_km` (double)
- `updated_at` (DateTime no backend Supabase) – necessário para sync incremental

## DTO/Model existente
Arquivo: `lib/features/goals/data/models/weekly_goal_model.dart`
Métodos: `fromJson`, `toJson`, `fromEntity`, `toEntity`
Necessário adaptar geração para usar `WeeklyGoalModel.fromJson(row)`.

## Objetivo dos arquivos a gerar
1. `weekly_goals_remote_datasource_supabase.dart` (remote datasource Supabase)
2. `weekly_goals_repository_impl.dart` (implementação concreta do repositório, incluindo sync)

## Regras (adaptadas do prompt genérico)
### Remote Datasource
- Classe: `SupabaseWeeklyGoalsRemoteDatasource`
- Construtor aceita `SupabaseClient? client`
- Método principal: `fetchWeeklyGoals({DateTime? since, int limit = 500, PageCursor? cursor})`
  - Aplica filtro `.gte('updated_at', since.toIso8601String())` se `since` for fornecido
  - Ordena por `updated_at DESC`
  - Pagina via `range(offset, offset+limit-1)` onde offset vem de `cursor.value` se int
  - Mapeia linhas para `WeeklyGoalModel` usando `fromJson`
  - Retorna `RemotePage<WeeklyGoalModel>` com `next` se tamanho == limit
  - Em qualquer exceção: retorna `RemotePage(items: [])` e loga erro (kDebugMode)
- Logs (kDebugMode): quantidade recebida, parâmetros usados, erro em caso de falha.
- Comentário introdutório explicando papel, dicas de robustez e referência a arquivos de debug.
- Bloco final com exemplo de uso + checklist de erros.

### Repository Impl
- Classe: `WeeklyGoalsRepositoryImplRemote` (evitar conflito com já existente local) implementando `WeeklyGoalsRepository`
- Construtor: recebe `SupabaseWeeklyGoalsRemoteDatasource remoteApi` e `WeeklyGoalsLocalDao localDao`
- Mantém chave `_lastSyncKey = 'weekly_goals_last_sync_v1'`
- Métodos da interface:
  - `loadFromCache()`: usa DAO -> converte entidades já prontas (DAO já retorna entidade) – se necessário adaptar
  - `syncFromServer()`: lê last sync (SharedPreferences), chama `remoteApi.fetchWeeklyGoals(since: lastSync)`, converte para entidade via model, salva cada com `localDao.save(entity)`, atualiza lastSync com maior `updated_at` (parse defensivo), retorna count
  - `listAll()`: DAO
  - `listFeatured()`: filtra progresso > 0 e < 1
  - `getById(String id)`: DAO + find
- Logs (kDebugMode): início do sync, lastSync lido, quantidade recebida, maior `updated_at` aplicado.
- Tratamento defensivo para datas malformadas.
- Comentário introdutório + bloco final com exemplo e checklist.

## Checklist Específico WeeklyGoal
- Necessário garantir que `WeeklyGoalModel.fromJson` suporte id string/uuid
- Adicionar parse seguro para `updated_at` (nullable, fallback to now UTC)
- Evitar duplicar lógica de conversão (usar model direto)
- Garantir que localDao possui métodos adequados: `loadAllForUser(userId)`, `save(goal)` – para sync global, usar `_defaultUserId` ou iterar se multi-usuário (por enquanto usar `'default-user'`)

## Saída Esperada (Resumo)
Gerar DOIS arquivos, cada um com:
- Comentário introdutório didático
- Classe concreta conforme requisitos
- Logs kDebugMode
- Tratamento de erro
- Bloco comentado final (exemplo + checklist + referências)

## NÃO FAZER AGORA
- Não executar o prompt
- Não gerar os arquivos reais
- Apenas preparar este prompt adaptado

## Referências internas
- Arquivos de debug citados (supabase_init_debug_prompt.md, supabase_rls_remediation.md) podem ser mencionados no texto gerado.

---
## Pronto para execução futura
Quando for executar: substituir `PageCursor` e `RemotePage` por implementações reais (se ainda não existirem) ou gerar mocks.
