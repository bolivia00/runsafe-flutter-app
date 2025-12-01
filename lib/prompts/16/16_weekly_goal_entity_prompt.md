# Prompt Adaptado 16 para WeeklyGoal

> Baseado em: `16_providers_page_sync_prompt.md`
> Função: Integrar sincronização Supabase na página de listagem de metas semanais.

## Objetivo
Gerar as alterações necessárias na tela de listagem de metas (`WeeklyGoalListPage` ou variantes) para que ela use o datasource remoto + repositório e execute uma sincronização quando apropriado.

## Contexto
- Projeto usa DAO local (`WeeklyGoalsLocalDao`) e repository remoto (`WeeklyGoalsRepositoryImplRemote`).
- Datasource: `SupabaseWeeklyGoalsRemoteDatasource`.
- Provider existente: `WeeklyGoalsProvider` já envolve o repositório.
- UI atual consome `WeeklyGoal` via provider.

## Alterações a serem aplicadas

### 1. Verificar imports na página de listagem
Garantir que a página importa o provider:
```dart
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';
```

### 2. Modificar método de carregamento
O provider já possui método `load()` que:
- Carrega do cache primeiro (rápido)
- Executa sync em background
- Recarrega lista após sync

**Se ainda não implementado**, ajustar para incluir:
- Logs kDebugMode nos principais pontos
- Comentários explicativos sobre cada etapa
- Verificação de `mounted` antes de `notifyListeners()`
- Try/catch robusto com tratamento de erros

### 3. RefreshIndicator
Garantir que a lista tenha `RefreshIndicator` funcional:
```dart
RefreshIndicator(
  onRefresh: () async {
    await Provider.of<WeeklyGoalsProvider>(context, listen: false).syncNow();
  },
  child: ListView(...),
)
```

**IMPORTANTE**: Mesmo quando lista vazia, usar `AlwaysScrollableScrollPhysics()` para permitir pull-to-refresh.

### 4. Exemplo de logs esperados
```dart
if (kDebugMode) {
  print('[WeeklyGoalsProvider] Carregando do cache...');
  print('[WeeklyGoalsProvider] Sync iniciado');
  print('[WeeklyGoalsProvider] Sync concluído: X metas atualizadas');
}
```

## Motivação e benefícios
- Popula automaticamente o cache na primeira execução
- Permite atualização manual via pull-to-refresh
- Mantém separação de responsabilidades: UI → Provider → Repository → Datasource

## Precondições
- Supabase inicializado em `main.dart`
- Tabela `weekly_goals` criada no Supabase (será feito depois)
- `WeeklyGoalsRepositoryImplRemote` e `SupabaseWeeklyGoalsRemoteDatasource` existentes

## Validação
1. `flutter analyze` sem erros
2. Executar app e abrir tela de metas
3. Primeira execução: lista preenchida do remoto
4. Pull-to-refresh: sincroniza novamente

## Checklist de erros comuns
- ❌ Não verificar `mounted` antes de `setState`/`notifyListeners()`
- ❌ Não ter `RefreshIndicator` em lista vazia
- ❌ Não usar `AlwaysScrollableScrollPhysics()` quando vazio
- ❌ Não logar pontos críticos para debug
- ❌ Try/catch sem tratamento adequado

## Observações Adicionais

### Backup e Refatoração
**IMPORTANTE**: Antes de modificar qualquer arquivo:
1. Faça backup da versão atual (copie ou use git stash)
2. Se a página já tiver lógica de sincronização antiga, remova completamente
3. Não misture padrões antigos com o novo (use APENAS o provider)

### Limpeza de Arquivos Antigos
Após implementar com sucesso:
- Remova imports não utilizados
- Delete comentários TODO antigos
- Verifique se não há código duplicado de sync
- Execute `flutter analyze` para garantir qualidade

### Quando Refatorar
**Sinais de que precisa refatorar:**
- Sync é chamado diretamente na página (sem provider)
- Lógica de estado duplicada em múltiplos widgets
- Callbacks manuais de refresh sem RefreshIndicator

**Refatoração recomendada:**
- Centralize toda lógica de sync no provider
- Use RefreshIndicator para UX consistente
- Mantenha a página como apresentação pura (stateless quando possível)

### Estratégia de Sincronização Detalhada
- **Ao carregar a página**: Carrega do cache local (rápido)
- **Pull-to-refresh**: Dispara sync incremental do servidor
- **Sincronização incremental**: Usa `updated_at >= lastSync` para buscar apenas mudanças
- **Chave de controle**: `weekly_goals_last_sync_v1` no SharedPreferences

### Exemplo de Logs com Formato
```dart
if (kDebugMode) {
  print('[WeeklyGoalsProvider] Carregando do cache...');
  print('[WeeklyGoalsProvider] Sync iniciado');
  print('[WeeklyGoalsProvider] Sync concluído: X metas atualizadas');
}
```

## Referências
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Flutter RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Provider pattern: https://pub.dev/packages/provider
