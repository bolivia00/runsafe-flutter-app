# Prompt Adaptado 16 para RunningRoute

> Baseado em: `16_providers_page_sync_prompt.md`
> Função: Integrar sincronização Supabase na página de listagem de rotas de corrida.

## Objetivo
Gerar as alterações necessárias na tela de listagem de rotas (`RunningRouteListPage`) para que ela use o datasource remoto + repositório e execute sincronização.

## Contexto
- Projeto usa DAO local (`RunningRoutesLocalDaoSharedPrefs`) e repository remoto (`RunningRoutesRepositoryImplRemote`).
- Datasource: `SupabaseRunningRoutesRemoteDatasource`.
- UI pode precisar de provider wrapper se ainda não existir.
- RunningRoute possui lista aninhada de Waypoints - payload maior que outras entidades.

## Alterações a serem aplicadas

### 1. Criar provider se não existir
```dart
class RunningRoutesProvider extends ChangeNotifier {
  final RunningRoutesRepository _repository;
  
  List<RunningRoute> _routes = [];
  bool _isLoading = false;
  
  List<RunningRoute> get routes => _routes;
  bool get isLoading => _isLoading;
  
  RunningRoutesProvider(this._repository);
  
  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _routes = await _repository.loadFromCache();
      notifyListeners();
      
      await _repository.syncFromServer();
      _routes = await _repository.listAll();
    } catch (e) {
      if (kDebugMode) {
        print('[RunningRoutesProvider] Erro: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> syncNow() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.syncFromServer();
      _routes = await _repository.listAll();
    } catch (e) {
      if (kDebugMode) {
        print('[RunningRoutesProvider] Erro sync: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 2. Registrar provider em main.dart
```dart
ChangeNotifierProvider(
  create: (context) => RunningRoutesProvider(
    RunningRoutesRepositoryImplRemote(
      RunningRoutesLocalDaoSharedPrefs(),
      SupabaseRunningRoutesRemoteDatasource(Supabase.instance.client),
    ),
  )..loadRoutes(),
),
```

### 3. RefreshIndicator na página
```dart
RefreshIndicator(
  onRefresh: () async {
    await Provider.of<RunningRoutesProvider>(context, listen: false).syncNow();
  },
  child: ListView(...),
)
```

### 4. Exemplo de logs esperados
```dart
if (kDebugMode) {
  print('[RunningRoutesProvider] Carregando do cache...');
  print('[RunningRoutesProvider] Sync concluído: X rotas, Y waypoints totais');
}
```

## Motivação e benefícios
- Popula automaticamente o cache na primeira execução
- Permite atualização manual via pull-to-refresh
- Mantém separação de responsabilidades

## Precondições
- Supabase inicializado em `main.dart`
- Tabela `running_routes` criada no Supabase (será feito depois)
- `RunningRoutesRepositoryImplRemote` e `SupabaseRunningRoutesRemoteDatasource` existentes

## Validação
1. `flutter analyze` sem erros
2. Executar app e abrir tela de rotas
3. Primeira execução: lista preenchida do remoto
4. Pull-to-refresh: sincroniza novamente

## Checklist de erros comuns
- ❌ Não verificar `mounted` antes de `setState`/`notifyListeners()`
- ❌ Não ter `RefreshIndicator` em lista vazia
- ❌ Não usar `AlwaysScrollableScrollPhysics()` quando vazio
- ❌ Não logar pontos críticos para debug
- ❌ Erro ao parsear lista de waypoints aninhada

## Notas importantes
- RunningRoute tem payload maior (lista de waypoints) - considerar limit menor na paginação (200 vs 500)
- Validação: rota precisa de pelo menos 1 waypoint
- Conversão robusta da lista aninhada de waypoints (JSON → DTO → Entity)

## Observações Adicionais

### Backup e Refatoração
**IMPORTANTE**: Antes de modificar qualquer arquivo:
1. Faça backup da versão atual (copie ou use git stash)
2. Se a página já tiver lógica de sincronização antiga, remova completamente
3. Não misture padrões antigos com o novo (use APENAS o provider)
4. **Atenção especial**: RunningRoute tem waypoints aninhados - verifique deserialização completa

### Limpeza de Arquivos Antigos
Após implementar com sucesso:
- Remova imports não utilizados
- Delete comentários TODO antigos
- Verifique se não há código duplicado de sync
- **Específico de RunningRoute**: Confirme que waypoints são carregados corretamente (não apenas a rota)
- Execute `flutter analyze` para garantir qualidade

### Quando Refatorar
**Sinais de que precisa refatorar:**
- Sync é chamado diretamente na página (sem provider)
- Waypoints carregados separadamente da rota (deve ser aninhado)
- Lógica de estado duplicada em múltiplos widgets
- Callbacks manuais de refresh sem RefreshIndicator

**Refatoração recomendada:**
- Centralize toda lógica de sync no provider
- Mantenha deserialização de waypoints no repository/datasource layer
- Use RefreshIndicator para UX consistente
- Mantenha a página como apresentação pura
- **Performance**: Considere paginação se lista de rotas crescer muito (payload grande)

### Registro do Provider
**Não esqueça** de registrar o novo provider em `main.dart`:
```dart
ChangeNotifierProvider(
  create: (context) => RunningRoutesProvider(
    RunningRoutesRepositoryImplRemote(
      RunningRoutesLocalDaoSharedPrefs(),
      SupabaseRunningRoutesRemoteDatasource(Supabase.instance.client),
    ),
  )..loadRoutes(),
),
```

### Estratégia de Sincronização Detalhada
- **Ao carregar a página**: Carrega do cache local (rápido)
- **Pull-to-refresh**: Busca rotas novas/atualizadas com waypoints aninhados
- **Payload maior**: RunningRoute contém lista de waypoints (limit 200 vs 500 de outras entidades)
- **Sincronização incremental**: Filtra por `updated_at >= lastSync`
- **Estrutura aninhada**: Waypoints são deserializados junto com a rota
- **Chave de controle**: `running_routes_last_sync_v1` no SharedPreferences

### Exemplo de Logs com Formato
```dart
if (kDebugMode) {
  print('[RunningRoutesProvider] Carregando do cache...');
  print('[RunningRoutesProvider] Sync iniciado');
  print('[RunningRoutesProvider] Sync concluído: X rotas, Y waypoints totais');
}
```

## Referências
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md`
- Flutter RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Provider pattern: https://pub.dev/packages/provider
- Nested JSON serialization: https://docs.flutter.dev/data-and-backend/serialization/json
