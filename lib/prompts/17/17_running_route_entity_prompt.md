# 17 - UI Domain Refactor: RunningRoute (versão didática)

> **Este prompt foi adaptado para fins didáticos. As alterações e refatorações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug, facilitando o aprendizado e a implementação correta.**

## Contexto
Este prompt documenta as mudanças necessárias para que a UI de `RunningRoute` pare de usar `RunningRouteDto` diretamente e passe a usar a entidade de domínio `RunningRoute` no código de apresentação. A conversão é realizada na fronteira com a persistência (DAO) via `RunningRouteMapper`.

## Arquivos a serem modificados

### 1. `lib/features/routes/presentation/pages/running_route_list_page.dart`
- Usar `List<RunningRoute>` no estado da UI e widgets
- Ao ler do DAO local, converter DTO → domínio via `RunningRouteMapper.toEntity`
- Ao persistir, converter domínio → DTO via `RunningRouteMapper.toDto` e chamar métodos do DAO
- O novo provider (`RunningRoutesProvider`) já usa entidades de domínio, então a página deve apenas consumir `provider.routes`
- **Nota**: A página já foi refatorada no Prompt 16 para usar o provider, então este prompt foca em garantir que não há uso direto de DTOs

### 2. `lib/features/routes/presentation/widgets/running_route_form_dialog.dart`
- Produzir e aceitar valores `RunningRoute` de domínio no dialog de formulário
- Garantir que waypoints sejam manipulados como entidades de domínio

### 3. `lib/features/routes/presentation/widgets/running_route_list_widget.dart` (se existir)
- Aceitar lista de `RunningRoute` de domínio e encaminhar objetos de domínio para widgets filhos

## Por que essa mudança
- Manter a camada de apresentação desacoplada de DTOs e estrutura de persistência
- Simplificar código da UI (focado em domínio) e concentrar lógica de mapeamento em `RunningRouteMapper`
- **Facilita testes, manutenção e evolução do código, além de evitar bugs comuns de conversão e dependência entre camadas**

## Como o mapeamento é feito (padrão)

### Leitura do cache local (já implementado no provider):
```dart
// No RunningRoutesRepositoryImplRemote
final dtoList = await _localDao.listAll();
final domainList = dtoList.map(_mapper.toEntity).toList();
// Comentário: Sempre converta DTO → domínio na fronteira de persistência para manter a UI desacoplada
return domainList;
```

### Persistir mudanças da UI (criar/editar/remover):
```dart
// Quando implementar métodos de escrita no provider
final newDto = _mapper.toDto(domainEntity);
await _localDao.upsertAll([newDto]);
// Comentário: Converta domínio → DTO apenas ao persistir, mantendo a lógica de mapeamento centralizada
```

## Sincronização com Supabase

- O `RunningRoutesProvider` já implementa sincronização usando `RunningRoutesRepositoryImplRemote`
- A sincronização já está integrada via `RefreshIndicator` (Prompt 16)
- **Inclua prints/logs (usando kDebugMode) nos principais pontos do fluxo:**

```dart
if (kDebugMode) {
  print('[RunningRouteListPage] iniciando sync com Supabase...');
  print('[RunningRoutesProvider] Sync concluído: X rotas, Y waypoints totais');
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
     - `[RunningRouteListPage] iniciando sync com Supabase...`
     - `[RunningRoutesRepositoryImplRemote] syncFromServer: aplicados X registros ao cache`

3. **Checklist de erros comuns:**
   - ❌ Erro de conversão de tipos: garanta que o Mapper aceita múltiplos formatos vindos do backend
   - ❌ Falha ao atualizar UI após sync: sempre verifique se o widget está mounted antes de chamar setState/notifyListeners
   - ❌ Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão
   - ❌ Waypoints não carregados corretamente: verifique deserialização da lista aninhada (JSON → DTO → Entity)
   - ❌ Problemas de integração com Supabase (RLS, inicialização): consulte `supabase_rls_remediation.md` e `supabase_init_debug_prompt.md`

## Notas importantes

### RefreshIndicator em lista vazia
⚠️ **Erro comum**: quando a lista está vazia (`routes.isEmpty`), se você apenas mostrar uma mensagem "Nenhuma rota", usuários não podem fazer pull-to-refresh para sincronizar.

**Solução**: sempre envolva o estado vazio com `RefreshIndicator` + `ListView` com `AlwaysScrollableScrollPhysics()` para habilitar pull-to-refresh mesmo quando vazio. Veja prompt 12 (`12_agent_list_refresh.md`) para exemplo completo de implementação.

### Particularidades de RunningRoute
- **Payload maior**: Contém lista aninhada de waypoints (estrutura mais complexa)
- **Limit reduzido**: Considerar limit 200 vs 500 de outras entidades devido ao tamanho
- **Validação**: Rota precisa de pelo menos 1 waypoint
- **Conversão robusta**: JSON → DTO → Entity para lista aninhada de waypoints

## Referências úteis
- `running_routes_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (exemplo RefreshIndicator)
- Prompt 15: `15_running_route_entity_prompt.md` (datasource remoto)
- Prompt 16: `16_running_route_entity_prompt.md` (provider + page sync)

## Estado atual do projeto

**✅ Já implementado (Prompt 16):**
- Provider `RunningRoutesProvider` usa entidades de domínio
- Página `running_route_list_page.dart` consome `provider.routes` (já usa domínio)
- RefreshIndicator com sincronização remota
- AlwaysScrollableScrollPhysics em lista vazia

**⏳ Pendente:**
- Verificar se formulários (`running_route_form_dialog.dart`) usam entidades de domínio
- Implementar métodos de escrita no provider (add/edit/delete) se necessário
- Remover qualquer uso residual de DTOs na camada de apresentação

**📊 Tabela Supabase (ainda não criada):**
- Nome: `running_routes`
- Campos: `id`, `name`, `waypoints` (JSONB), `featured`, `updated_at`, `created_at`
- Trigger: `updated_at` automático
- RLS: Política de acesso público ou por usuário
