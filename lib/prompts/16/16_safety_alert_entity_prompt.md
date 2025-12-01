# Prompt Adaptado 16 para SafetyAlert

> Baseado em: `16_providers_page_sync_prompt.md`
> Função: Integrar sincronização Supabase na página de listagem de alertas de segurança.

## Objetivo
Gerar as alterações necessárias na tela de listagem de alertas (`SafetyAlertListPage`) para que ela use o datasource remoto + repositório e execute sincronização.

## Contexto
- Projeto usa DAO local (`SafetyAlertsLocalDaoSharedPrefs`) e repository remoto (`SafetyAlertsRepositoryImplRemote`).
- Datasource: `SupabaseSafetyAlertsRemoteDatasource`.
- Provider existente: `SafetyAlertsProvider` já envolve o repositório.
- UI atual consome `SafetyAlert` via provider.

## Alterações a serem aplicadas

### 1. Verificar imports na página de listagem
Garantir que a página importa o provider:
```dart
import 'package:runsafe/features/alerts/presentation/providers/safety_alerts_provider.dart';
```

### 2. Modificar método de carregamento
O provider já possui método `loadAlerts()` que:
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
    await Provider.of<SafetyAlertsProvider>(context, listen: false).syncNow();
  },
  child: ListView(...),
)
```

**IMPORTANTE**: Mesmo quando lista vazia, usar `AlwaysScrollableScrollPhysics()` para permitir pull-to-refresh.

### 4. Exemplo de logs esperados
```dart
if (kDebugMode) {
  print('[SafetyAlertsProvider] Carregando do cache...');
  print('[SafetyAlertsProvider] Sync iniciado');
  print('[SafetyAlertsProvider] Sync concluído: X alertas atualizados');
}
```

## Motivação e benefícios
- Popula automaticamente o cache na primeira execução
- Permite atualização manual via pull-to-refresh
- Mantém separação de responsabilidades: UI → Provider → Repository → Datasource

## Precondições
- Supabase inicializado em `main.dart`
- Tabela `safety_alerts` criada no Supabase (será feito depois)
- `SafetyAlertsRepositoryImplRemote` e `SupabaseSafetyAlertsRemoteDatasource` existentes

## Validação
1. `flutter analyze` sem erros
2. Executar app e abrir tela de alertas
3. Primeira execução: lista preenchida do remoto
4. Pull-to-refresh: sincroniza novamente

## Checklist de erros comuns
- ❌ Não verificar `mounted` antes de `setState`/`notifyListeners()`
- ❌ Não ter `RefreshIndicator` em lista vazia
- ❌ Não usar `AlwaysScrollableScrollPhysics()` quando vazio
- ❌ Não logar pontos críticos para debug
- ❌ Try/catch sem tratamento adequado

## Nota importante
SafetyAlert possui enum `AlertType` - garantir conversão string ↔ enum robusta no sync.

## Observações Adicionais

### Backup e Refatoração
**IMPORTANTE**: Antes de modificar qualquer arquivo:
1. Faça backup da versão atual (copie ou use git stash)
2. Se a página já tiver lógica de sincronização antiga, remova completamente
3. Não misture padrões antigos com o novo (use APENAS o provider)
4. **Atenção especial**: SafetyAlert usa enum `AlertType` - verifique conversões

### Limpeza de Arquivos Antigos
Após implementar com sucesso:
- Remova imports não utilizados
- Delete comentários TODO antigos
- Verifique se não há código duplicado de sync
- **Específico de SafetyAlert**: Confirme que não há conversão manual de enums em múltiplos lugares
- Execute `flutter analyze` para garantir qualidade

### Quando Refatorar
**Sinais de que precisa refatorar:**
- Sync é chamado diretamente na página (sem provider)
- Conversão de AlertType feita manualmente na UI
- Lógica de estado duplicada em múltiplos widgets
- Callbacks manuais de refresh sem RefreshIndicator

**Refatoração recomendada:**
- Centralize toda lógica de sync no provider
- Mantenha conversão de enum apenas no repository layer
- Use RefreshIndicator para UX consistente
- Mantenha a página como apresentação pura

### Estratégia de Sincronização Detalhada
- **Ao carregar a página**: Carrega do cache local (instant load)
- **Pull-to-refresh**: Busca alertas novos/atualizados do servidor
- **Sincronização incremental**: Filtra por `updated_at >= lastSync`
- **Conversão de dados**: AlertType enum convertido corretamente (remote string → domain enum)
- **Chave de controle**: `safety_alerts_last_sync_v1` no SharedPreferences

### Exemplo de Logs com Formato
```dart
if (kDebugMode) {
  print('[SafetyAlertsProvider] Carregando do cache...');
  print('[SafetyAlertsProvider] Sync iniciado');
  print('[SafetyAlertsProvider] Sync concluído: X alertas atualizados');
}
```

## Referências
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Flutter RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Provider pattern: https://pub.dev/packages/provider
