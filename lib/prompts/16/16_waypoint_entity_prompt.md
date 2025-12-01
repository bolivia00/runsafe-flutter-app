# Prompt Adaptado 16 para Waypoint

> Baseado em: `16_providers_page_sync_prompt.md`
> Função: Integrar sincronização Supabase na página de listagem de waypoints.

## Objetivo
Gerar as alterações necessárias na tela de listagem de waypoints (`WaypointListPage`) para que ela use o datasource remoto + repositório e execute sincronização.

## Contexto
- Projeto usa DAO local (`WaypointsLocalDaoSharedPrefs`) e repository remoto (`WaypointsRepositoryImplRemote`).
- Datasource: `SupabaseWaypointsRemoteDatasource`.
- UI pode precisar de provider wrapper se ainda não existir.
- Waypoint não possui ID explícito - usa `timestamp.toIso8601String()` como chave.

## Alterações a serem aplicadas

### 1. Criar provider se não existir
```dart
class WaypointsProvider extends ChangeNotifier {
  final WaypointsRepository _repository;
  
  List<Waypoint> _waypoints = [];
  bool _isLoading = false;
  
  List<Waypoint> get waypoints => _waypoints;
  bool get isLoading => _isLoading;
  
  WaypointsProvider(this._repository);
  
  Future<void> loadWaypoints() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _waypoints = await _repository.loadFromCache();
      notifyListeners();
      
      await _repository.syncFromServer();
      _waypoints = await _repository.listAll();
    } catch (e) {
      if (kDebugMode) {
        print('[WaypointsProvider] Erro: $e');
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
      _waypoints = await _repository.listAll();
    } catch (e) {
      if (kDebugMode) {
        print('[WaypointsProvider] Erro sync: $e');
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
  create: (context) => WaypointsProvider(
    WaypointsRepositoryImplRemote(
      WaypointsLocalDaoSharedPrefs(),
      SupabaseWaypointsRemoteDatasource(Supabase.instance.client),
    ),
  )..loadWaypoints(),
),
```

### 3. RefreshIndicator na página
```dart
RefreshIndicator(
  onRefresh: () async {
    await Provider.of<WaypointsProvider>(context, listen: false).syncNow();
  },
  child: ListView(...),
)
```

### 4. Exemplo de logs esperados
```dart
if (kDebugMode) {
  print('[WaypointsProvider] Carregando do cache...');
  print('[WaypointsProvider] Sync concluído: X waypoints');
}
```

## Motivação e benefícios
- Popula automaticamente o cache na primeira execução
- Permite atualização manual via pull-to-refresh
- Mantém separação de responsabilidades

## Precondições
- Supabase inicializado em `main.dart`
- Tabela `waypoints` criada no Supabase (será feito depois)
- `WaypointsRepositoryImplRemote` e `SupabaseWaypointsRemoteDatasource` existentes

## Validação
1. `flutter analyze` sem erros
2. Executar app e abrir tela de waypoints
3. Primeira execução: lista preenchida do remoto
4. Pull-to-refresh: sincroniza novamente

## Checklist de erros comuns
- ❌ Não verificar `mounted` antes de `setState`/`notifyListeners()`
- ❌ Não ter `RefreshIndicator` em lista vazia
- ❌ Não usar `AlwaysScrollableScrollPhysics()` quando vazio
- ❌ Não logar pontos críticos para debug

## Nota importante
Waypoints usam timestamp ISO como ID - garantir parsing defensivo de datas.

## Observações Adicionais

### Backup e Refatoração
**IMPORTANTE**: Antes de modificar qualquer arquivo:
1. Faça backup da versão atual (copie ou use git stash)
2. Se a página já tiver lógica de sincronização antiga, remova completamente
3. Não misture padrões antigos com o novo (use APENAS o provider)
4. **Atenção especial**: Waypoint usa timestamp como ID - verifique conversões ISO 8601

### Limpeza de Arquivos Antigos
Após implementar com sucesso:
- Remova imports não utilizados
- Delete comentários TODO antigos
- Verifique se não há código duplicado de sync
- **Específico de Waypoint**: Confirme que timestamp é tratado consistentemente (DateTime ↔ String ISO)
- Execute `flutter analyze` para garantir qualidade

### Quando Refatorar
**Sinais de que precisa refatorar:**
- Sync é chamado diretamente na página (sem provider)
- Conversão de timestamp feita manualmente na UI
- Lógica de estado duplicada em múltiplos widgets
- Callbacks manuais de refresh sem RefreshIndicator

**Refatoração recomendada:**
- Centralize toda lógica de sync no provider
- Mantenha conversão de timestamp apenas no repository/datasource layer
- Use RefreshIndicator para UX consistente
- Mantenha a página como apresentação pura

### Registro do Provider
**Não esqueça** de registrar o novo provider em `main.dart`:
```dart
ChangeNotifierProvider(
  create: (context) => WaypointsProvider(
    WaypointsRepositoryImplRemote(
      WaypointsLocalDaoSharedPrefs(),
      SupabaseWaypointsRemoteDatasource(Supabase.instance.client),
    ),
  )..loadWaypoints(),
),
```

### Estratégia de Sincronização Detalhada
- **Ao carregar a página**: Carrega do cache local (rápido)
- **Pull-to-refresh**: Busca waypoints novos/atualizados do servidor
- **ID único**: Usa `timestamp.toIso8601String()` como identificador
- **Sincronização incremental**: Filtra por `updated_at >= lastSync`
- **Chave de controle**: `waypoints_last_sync_v1` no SharedPreferences

### Exemplo de Logs com Formato
```dart
if (kDebugMode) {
  print('[WaypointsProvider] Carregando do cache...');
  print('[WaypointsProvider] Sync iniciado');
  print('[WaypointsProvider] Sync concluído: X waypoints atualizados');
}
```

## Referências
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md`
- Flutter RefreshIndicator: https://api.flutter.dev/flutter/material/RefreshIndicator-class.html
- Provider pattern: https://pub.dev/packages/provider
- ISO 8601 DateTime: https://api.dart.dev/stable/dart-core/DateTime/toIso8601String.html
