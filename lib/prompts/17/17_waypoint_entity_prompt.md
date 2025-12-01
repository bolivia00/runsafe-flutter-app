# 17 - UI Domain Refactor: Waypoint (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações e refatorações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta.**

## Contexto
Este prompt documenta as mudanças necessárias para que a UI de `Waypoint` pare de usar `WaypointDto` diretamente e passe a usar a entidade de domínio `Waypoint` no código de apresentação. A conversão é realizada na fronteira com a persistência (DAO) via `WaypointMapper`.

## Arquivos a serem modificados

### 1. `lib/features/routes/presentation/pages/waypoint_list_page.dart`
- Usar `List<Waypoint>` no estado da UI e widgets
- Ao ler do DAO local, converter DTO → domínio via `WaypointMapper.toEntity`
- Ao persistir, converter domínio → DTO via `WaypointMapper.toDto` e chamar métodos do DAO
- O novo provider (`WaypointsProvider`) já usa entidades de domínio, então a página deve apenas consumir `provider.waypoints`
- **Nota**: A página já foi refatorada no Prompt 16 para usar o provider, então este prompt foca em garantir que não há uso direto de DTOs

### 2. `lib/features/routes/presentation/widgets/waypoint_form_dialog.dart`
- Produzir e aceitar valores `Waypoint` de domínio no dialog de formulário
- Garantir que o `timestamp` seja manipulado corretamente como DateTime

### 3. `lib/features/routes/presentation/widgets/waypoint_list_item.dart` (se existir)
- Aceitar `Waypoint` de domínio e usar campos do domínio na UI

## Por que essa mudança
- Manter a camada de apresentação desacoplada de DTOs e estrutura de persistência
- Simplificar código da UI (focado em domínio) e concentrar lógica de mapeamento em `WaypointMapper`
- **Facilita testes, manutenção e evolução do código, além de evitar bugs comuns de conversão e dependência entre camadas**
- **Importante para Waypoint**: Centraliza conversão de timestamp (DateTime ↔ String ISO 8601) no mapper

## Como o mapeamento é feito (padrão)

### Leitura do cache local (já implementado no provider):
```dart
// No WaypointsRepositoryImplRemote
final dtoList = await _localDao.listAll();
final domainList = dtoList.map((dto) {
  // Conversão de timestamp String ISO → DateTime acontece no mapper
  return WaypointMapper.toEntity(dto);
}).toList();
// Comentário: Sempre converta DTO → domínio na fronteira de persistência
return domainList;
```

### Persistir mudanças da UI (criar/editar/remover):
```dart
// Quando implementar métodos de escrita no provider
final newDto = WaypointMapper.toDto(domainEntity); // DateTime → String ISO
await _localDao.upsertAll([newDto]);
// Comentário: Converta domínio → DTO apenas ao persistir
```

## Sincronização com Supabase

- O `WaypointsProvider` já implementa sincronização usando `WaypointsRepositoryImplRemote`
- A sincronização já está integrada via `RefreshIndicator` (Prompt 16)
- **Inclua prints/logs (usando kDebugMode) nos principais pontos do fluxo:**

```dart
if (kDebugMode) {
  print('[WaypointListPage] iniciando sync com Supabase...');
  print('[WaypointsProvider] Sync concluído: X waypoints atualizados');
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
     - `[WaypointListPage] iniciando sync com Supabase...`
     - `[WaypointsRepositoryImplRemote] syncFromServer: aplicados X registros ao cache`

3. **Checklist de erros comuns:**
   - ❌ Erro de parsing de timestamp: garanta que o Mapper aceita múltiplos formatos ISO 8601 vindos do backend
   - ❌ Timestamp inconsistente: mantenha conversão DateTime ↔ String ISO APENAS no mapper, nunca na UI
   - ❌ Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState/notifyListeners
   - ❌ Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão
   - ❌ ID duplicado: Waypoint usa `timestamp.toIso8601String()` como ID - garanta unicidade
   - ❌ Problemas de integração com Supabase (RLS, inicialização): consulte `supabase_rls_remediation.md` e `supabase_init_debug_prompt.md`

## Notas importantes

### RefreshIndicator em lista vazia
⚠️ **Erro comum**: quando a lista está vazia (`waypoints.isEmpty`), se você apenas mostrar uma mensagem "Nenhum waypoint", usuários não podem fazer pull-to-refresh para sincronizar.

**Solução**: sempre envolva o estado vazio com `RefreshIndicator` + `ListView` com `AlwaysScrollableScrollPhysics()` para habilitar pull-to-refresh mesmo quando vazio. Veja prompt 12 (`12_agent_list_refresh.md`) para exemplo completo de implementação.

### Particularidades de Waypoint
- **Timestamp como ID**: Usa `timestamp.toIso8601String()` como identificador único
- **Formato ISO 8601**: Parsing defensivo de datas (aceitar múltiplos formatos)
- **Coordenadas**: Campos `latitude` e `longitude` com precisão decimal
- **Uso em RunningRoute**: Waypoints são frequentemente usados como lista aninhada em rotas

## Referências úteis
- `waypoints_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Prompt 15: `15_waypoint_entity_prompt.md` (datasource remoto)
- Prompt 16: `16_waypoint_entity_prompt.md` (provider + page sync)
- ISO 8601 DateTime: https://api.dart.dev/stable/dart-core/DateTime/toIso8601String.html

## Estado atual do projeto

**✅ Já implementado (Prompt 16):**
- Provider `WaypointsProvider` usa entidades de domínio
- Página `waypoint_list_page.dart` consome `provider.waypoints` (já usa domínio)
- RefreshIndicator com sincronização remota
- AlwaysScrollableScrollPhysics em lista vazia
- Conversão de timestamp no repository layer

**⏳ Pendente:**
- Verificar se formulários (`waypoint_form_dialog.dart`) usam entidades de domínio
- Implementar métodos de escrita no provider (add/edit/delete) se necessário
- Remover qualquer uso residual de DTOs na camada de apresentação

**📊 Tabela Supabase (ainda não criada):**
- Nome: `waypoints`
- Campos: `latitude`, `longitude`, `timestamp` (TIMESTAMPTZ como PK), `updated_at`, `created_at`
- ID único: Campo `timestamp` usado como chave primária
- Trigger: `updated_at` automático
- RLS: Política de acesso público ou por usuário
