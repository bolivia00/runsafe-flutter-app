# 17 - UI Domain Refactor: SafetyAlert (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações e refatorações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta.**

## Contexto
Este prompt documenta as mudanças necessárias para que a UI de `SafetyAlert` pare de usar `SafetyAlertDto` diretamente e passe a usar a entidade de domínio `SafetyAlert` no código de apresentação. A conversão é realizada na fronteira com a persistência (DAO) via `SafetyAlertMapper`.

## Arquivos a serem modificados

### 1. `lib/features/alerts/presentation/pages/safety_alert_list_page.dart`
- Usar `List<SafetyAlert>` no estado da UI e widgets
- Ao ler do DAO local, converter DTO → domínio via `SafetyAlertMapper.toEntity`
- Ao persistir, converter domínio → DTO via `SafetyAlertMapper.toDto` e chamar métodos do DAO
- O novo provider (`SafetyAlertsProvider`) já usa entidades de domínio, então a página deve apenas consumir `provider.alerts`
- **Nota**: A página já foi refatorada no Prompt 16 para usar o provider, então este prompt foca em garantir que não há uso direto de DTOs

### 2. `lib/features/alerts/presentation/widgets/safety_alert_form_dialog.dart`
- Produzir e aceitar valores `SafetyAlert` de domínio no dialog de formulário
- Garantir que o enum `AlertType` seja manipulado corretamente

### 3. `lib/features/alerts/presentation/widgets/safety_alert_list_item.dart` (se existir)
- Aceitar `SafetyAlert` de domínio e usar campos do domínio na UI

## Por que essa mudança
- Manter a camada de apresentação desacoplada de DTOs e estrutura de persistência
- Simplificar código da UI (focado em domínio) e concentrar lógica de mapeamento em `SafetyAlertMapper`
- **Facilita testes, manutenção e evolução do código, além de evitar bugs comuns de conversão e dependência entre camadas**
- **Importante para SafetyAlert**: Centraliza conversão de enum `AlertType` (string ↔ enum) no mapper

## Como o mapeamento é feito (padrão)

### Leitura do cache local (já implementado no provider):
```dart
// No SafetyAlertsRepositoryImplRemote
final dtoList = await _localDao.listAll();
final domainList = dtoList.map((dto) {
  // Conversão de AlertType string → enum acontece no mapper
  return SafetyAlertMapper.toEntity(dto);
}).toList();
// Comentário: Sempre converta DTO → domínio na fronteira de persistência
return domainList;
```

### Persistir mudanças da UI (criar/editar/remover):
```dart
// Quando implementar métodos de escrita no provider
final newDto = SafetyAlertMapper.toDto(domainEntity); // enum → string
await _localDao.upsertAll([newDto]);
// Comentário: Converta domínio → DTO apenas ao persistir
```

## Sincronização com Supabase

- O `SafetyAlertsProvider` já implementa sincronização usando `SafetyAlertsRepositoryImplRemote`
- A sincronização já está integrada via `RefreshIndicator` (Prompt 16)
- **Inclua prints/logs (usando kDebugMode) nos principais pontos do fluxo:**

```dart
if (kDebugMode) {
  print('[SafetyAlertListPage] iniciando sync com Supabase...');
  print('[SafetyAlertsProvider] Sync concluído: X alertas atualizados');
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
     - `[SafetyAlertListPage] iniciando sync com Supabase...`
     - `[SafetyAlertsRepositoryImplRemote] syncFromServer: aplicados X registros ao cache`

3. **Checklist de erros comuns:**
   - ❌ Erro de conversão de enum: garanta que o Mapper aceita múltiplos formatos de string vindos do backend
   - ❌ AlertType inconsistente: mantenha conversão de enum APENAS no mapper, nunca na UI
   - ❌ Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState/notifyListeners
   - ❌ Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão
   - ❌ Problemas de integração com Supabase (RLS, inicialização): consulte `supabase_rls_remediation.md` e `supabase_init_debug_prompt.md`

## Notas importantes

### RefreshIndicator em lista vazia
⚠️ **Erro comum**: quando a lista está vazia (`alerts.isEmpty`), se você apenas mostrar uma mensagem "Nenhum alerta", usuários não podem fazer pull-to-refresh para sincronizar.

**Solução**: sempre envolva o estado vazio com `RefreshIndicator` + `ListView` com `AlwaysScrollableScrollPhysics()` para habilitar pull-to-refresh mesmo quando vazio. Veja prompt 12 (`12_agent_list_refresh.md`) para exemplo completo de implementação.

### Particularidades de SafetyAlert
- **Enum AlertType**: Conversão string ↔ enum deve ser robusta (aceitar múltiplos formatos)
- **Tipos disponíveis**: `pothole`, `noLighting`, `suspiciousActivity`, `other`
- **Severidade**: Campo `severity` (1-5) para filtrar alertas destacados (≥ 4)
- **Timestamp**: Campo `timestamp` usado para ordenação e display

## Referências úteis
- `safety_alerts_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Prompt 15: `15_safety_alert_entity_prompt.md` (datasource remoto)
- Prompt 16: `16_safety_alert_entity_prompt.md` (provider + page sync)

## Estado atual do projeto

**✅ Já implementado (Prompt 16):**
- Provider `SafetyAlertsProvider` usa entidades de domínio
- Página `safety_alert_list_page.dart` consome `provider.alerts` (já usa domínio)
- RefreshIndicator com sincronização remota
- AlwaysScrollableScrollPhysics em lista vazia
- Conversão de enum `AlertType` no repository layer

**⏳ Pendente:**
- Verificar se formulários (`safety_alert_form_dialog.dart`) usam entidades de domínio
- Implementar métodos de escrita no provider (add/edit/delete) se necessário
- Remover qualquer uso residual de DTOs na camada de apresentação

**📊 Tabela Supabase (ainda não criada):**
- Nome: `safety_alerts`
- Campos: `id`, `description`, `type` (STRING), `severity`, `latitude`, `longitude`, `timestamp`, `updated_at`, `created_at`
- Conversão: Campo `type` será convertido para enum `AlertType` no mapper
- Trigger: `updated_at` automático
- RLS: Política de acesso público ou por usuário
