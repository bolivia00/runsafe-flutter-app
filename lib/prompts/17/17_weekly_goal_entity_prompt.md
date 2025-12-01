# 17 - UI Domain Refactor: WeeklyGoal (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações e refatorações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta.**

## Contexto
Este prompt documenta as mudanças necessárias para que a UI de `WeeklyGoal` pare de usar `WeeklyGoalDto` diretamente e passe a usar a entidade de domínio `WeeklyGoal` no código de apresentação. A conversão é realizada na fronteira com a persistência (DAO) via `WeeklyGoalMapper`.

## Arquivos a serem modificados

### 1. `lib/features/goals/presentation/pages/weekly_goals_page.dart`
- Usar `List<WeeklyGoal>` no estado da UI e widgets
- O provider (`WeeklyGoalsProvider`) já usa entidades de domínio, então a página deve apenas consumir `provider.items`
- **Nota**: A página já foi refatorada no Prompt 16 para usar o provider, então este prompt foca em garantir que não há uso direto de DTOs

### 2. `lib/features/goals/presentation/widgets/goal_card.dart` (se existir)
- Aceitar `WeeklyGoal` de domínio e usar campos do domínio na UI

### 3. Dialogs de formulário (se existirem)
- Produzir e aceitar valores `WeeklyGoal` de domínio

## Por que essa mudança
- Manter a camada de apresentação desacoplada de DTOs e estrutura de persistência
- Simplificar código da UI (focado em domínio) e concentrar lógica de mapeamento em `WeeklyGoalMapper`
- **Facilita testes, manutenção e evolução do código, além de evitar bugs comuns de conversão e dependência entre camadas**

## Como o mapeamento é feito (padrão)

### Leitura do cache local (já implementado no provider):
```dart
// No WeeklyGoalsRepositoryImpl
final dtoList = await _localDao.listAll();
final domainList = dtoList.map(WeeklyGoalMapper.toEntity).toList();
// Comentário: Sempre converta DTO → domínio na fronteira de persistência
return domainList;
```

### Persistir mudanças da UI (criar/editar/remover):
```dart
// No WeeklyGoalsProvider (já implementado)
final newDto = WeeklyGoalMapper.toDto(domainEntity);
await _repositoryImpl.add(goal); // Usa o método auxiliar do repository
// Comentário: Converta domínio → DTO apenas ao persistir
```

## Sincronização com Supabase

- O `WeeklyGoalsProvider` já implementa sincronização inteligente
- A sincronização já está integrada via `RefreshIndicator` (Prompt 16)
- **Inclua prints/logs (usando kDebugMode) nos principais pontos do fluxo:**

```dart
if (kDebugMode) {
  print('[WeeklyGoalsPage] iniciando sync com Supabase...');
  print('[WeeklyGoalsProvider] Sync concluído: X metas (Y mudanças)');
}
```

## Passos de verificação

1. **Análise estática:**
```bash
flutter analyze
```

2. **Executar o app** (requer URL/anon key válidos do Supabase no ambiente):
   - Na primeira abertura com cache vazio, a barra de progresso aparece e sincroniza
   - Fluxos de adicionar, editar, deletar persistem via DAO (mapeamento domínio → DTO) e atualizam a lista
   - **Verifique os logs no console:**
     - `[WeeklyGoalsPage] iniciando sync com Supabase...`
     - `[WeeklyGoalsRepositoryImpl] syncFromServer: aplicados X registros ao cache`

3. **Checklist de erros comuns:**
   - ❌ Erro de conversão de tipos: garanta que o Mapper aceita múltiplos formatos vindos do backend
   - ❌ Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState/notifyListeners
   - ❌ Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão
   - ❌ Progresso não calculado corretamente: verifique que `progressPercentage` usa valores de domínio
   - ❌ Problemas de integração com Supabase (RLS, inicialização): consulte `supabase_rls_remediation.md` e `supabase_init_debug_prompt.md`

## Notas importantes

### RefreshIndicator em lista vazia
⚠️ **Erro comum**: quando a lista está vazia (`items.isEmpty`), se você apenas mostrar uma mensagem "Nenhuma meta", usuários não podem fazer pull-to-refresh para sincronizar.

**Solução**: sempre envolva o estado vazio com `RefreshIndicator` + `ListView` com `AlwaysScrollableScrollPhysics()` para habilitar pull-to-refresh mesmo quando vazio. Veja prompt 12 (`12_agent_list_refresh.md`) para exemplo completo de implementação.

### Particularidades de WeeklyGoal
- **Sync inteligente**: Provider detecta número de mudanças e só recarrega se necessário
- **Lógica de negócio**: Método `addRun(km)` na entidade de domínio para adicionar quilometragem
- **Progresso**: Propriedade calculada `progressPercentage` (currentKm / targetKm)
- **User ID**: Campo `userId` para filtrar metas por usuário ('default-user' se não autenticado)

## Referências úteis
- `weekly_goals_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Prompt 16: `16_weekly_goal_entity_prompt.md` (provider + page sync)

## Estado atual do projeto

**✅ Já implementado (Prompt 16):**
- Provider `WeeklyGoalsProvider` usa entidades de domínio
- Página `weekly_goals_page.dart` consome `provider.items` (já usa domínio)
- RefreshIndicator com sincronização remota (método `syncNow()`)
- AlwaysScrollableScrollPhysics em lista vazia
- Métodos de escrita já implementados (add, update, remove)

**⏳ Pendente:**
- Migrar de `WeeklyGoalsRepositoryImpl` (local) para repositório remoto com Supabase
- Remover qualquer uso residual de DTOs na camada de apresentação
- Verificar que todos os widgets usam entidades de domínio

**📊 Tabela Supabase (ainda não criada):**
- Nome: `weekly_goals`
- Campos: `id`, `user_id`, `target_km`, `current_km`, `week_start`, `week_end`, `updated_at`, `created_at`
- Índice: `user_id` para filtrar metas por usuário
- Trigger: `updated_at` automático
- RLS: Política para filtrar por `user_id` (cada usuário vê apenas suas metas)

## Observação importante

**Status de migração remota:**
- WeeklyGoal atualmente usa `WeeklyGoalsRepositoryImpl` (local apenas)
- Para sincronização remota completa, criar:
  - `WeeklyGoalsRemoteDatasourceSupabase`
  - `WeeklyGoalsRepositoryImplRemote`
- O provider já tem `syncNow()` implementado, pronto para quando o repositório remoto existir
