# 18 - Sincronização Bidirecional: RunningRoute (Push + Pull) - versão didática

> **Este prompt foi adaptado para fins didáticos. As alterações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug.**

## Resumo

Esta mudança implementa sincronização **bidirecional** para `RunningRoute` entre o cache local (SharedPreferences) e o Supabase:
1. **Push**: Envia rotas locais para o servidor
2. **Pull**: Busca atualizações remotas desde o último sync

## Contexto do Projeto

**Status atual**: 
- ✅ Pull incremental já implementado (Prompt 16)
- ✅ Mapper centralizado (Prompt 17)
- ⏳ Push para servidor **não implementado**
- ⏳ Tabela Supabase `running_routes` não criada

## Arquivos a serem modificados

### 1. `lib/features/routes/infrastructure/remote/running_routes_remote_datasource_supabase.dart`

**Adicionar método de upsert:**
```dart
/// Envia lista de rotas para o Supabase (upsert em lote)
/// Retorna número de rotas confirmadas pelo servidor
Future<int> upsertRunningRoutes(List<RunningRouteModel> models) async {
  try {
    if (kDebugMode) {
      print('[SupabaseRunningRoutesRemoteDatasource] upsertRunningRoutes: enviando ${models.length} rotas');
    }
    
    final data = models.map((m) => {
      'id': m.id,
      'name': m.name,
      'waypoints': m.waypoints.map((w) => {
        'latitude': w.latitude,
        'longitude': w.longitude,
        'timestamp': w.timestamp.toIso8601String(),
      }).toList(),
      'featured': m.featured ?? false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).toList();
    
    final response = await _client
      .from('running_routes')
      .upsert(data)
      .select();
    
    if (kDebugMode) {
      print('[SupabaseRunningRoutesRemoteDatasource] upsert response: ${response.length} rotas confirmadas');
    }
    
    return response.length;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseRunningRoutesRemoteDatasource] Erro no upsert: $e');
    }
    return 0; // Melhor esforço: erro não bloqueia pull
  }
}
```

### 2. `lib/features/routes/infrastructure/repositories/running_routes_repository_impl_remote.dart`

**Atualizar método `syncFromServer()` para Push + Pull:**

```dart
@override
Future<int> syncFromServer() async {
  final startedAt = DateTime.now().toUtc();
  
  // === FASE 1: PUSH (melhor esforço) ===
  try {
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Iniciando PUSH de rotas locais...');
    }
    
    // Lê todas as rotas do cache local
    final localDtos = await _localDao.listAll();
    
    if (localDtos.isNotEmpty) {
      // Converte para models do Supabase
      final models = localDtos.map((dto) {
        final entity = _mapper.toEntity(dto);
        return RunningRouteModel.fromEntity(entity);
      }).toList();
      
      // Envia para o servidor (upsert)
      final pushed = await _remote.upsertRunningRoutes(models);
      
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] PUSH concluído: $pushed rotas enviadas');
      }
    }
  } catch (e) {
    // Erro no push não bloqueia o pull
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Erro no PUSH (ignorado): $e');
    }
  }
  
  // === FASE 2: PULL (incremental desde lastSync) ===
  final lastSync = await _getLastSync();
  
  if (kDebugMode) {
    print('[RunningRoutesRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
  }
  
  final page = await _remote.fetchRunningRoutes(since: lastSync);
  final fetched = page.items;
  
  if (fetched.isEmpty) {
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] PULL: nenhuma rota nova/alterada.');
    }
    await _setLastSync(startedAt);
    return 0;
  }
  
  // Merge por ID
  final existingDtos = await _localDao.listAll();
  final existingById = {for (var d in existingDtos) d.route_id: d};
  
  int changes = 0;
  for (final model in fetched) {
    final entity = _modelToEntity(model);
    final dto = _mapper.toDto(entity);
    existingById[dto.route_id] = dto;
    changes++;
  }
  
  await _localDao.upsertAll(existingById.values.toList());
  
  if (kDebugMode) {
    final totalWaypoints = fetched.fold<int>(0, (sum, m) => sum + m.waypoints.length);
    print('[RunningRoutesRepositoryImplRemote] PULL concluído: $changes rotas, $totalWaypoints waypoints');
  }
  
  await _setLastSync(startedAt);
  return changes;
}
```

### 3. `lib/features/routes/presentation/providers/running_routes_provider.dart`

**Garantir que sync seja chamado sempre (não apenas quando vazio):**

```dart
Future<void> loadRoutes() async {
  if (_isLoading) return;
  
  _isLoading = true;
  notifyListeners();
  
  try {
    // Carrega cache local primeiro (responsividade)
    if (kDebugMode) {
      print('[RunningRoutesProvider] Carregando do cache...');
    }
    _routes = await _repository.loadFromCache();
    notifyListeners(); // Atualiza UI imediatamente
    
    // Sync bidirecional: SEMPRE executa (push + pull)
    if (kDebugMode) {
      print('[RunningRoutesProvider] Iniciando sync bidirecional...');
    }
    await _repository.syncFromServer();
    _routes = await _repository.listAll();
    
    if (kDebugMode) {
      print('[RunningRoutesProvider] Sync concluído: ${_routes.length} rotas totais');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[RunningRoutesProvider] Erro ao carregar: $e');
    }
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## Particularidades de RunningRoute

### 1. **Waypoints Aninhados**
```dart
// Serialização de lista aninhada para Supabase
'waypoints': model.waypoints.map((w) => {
  'latitude': w.latitude,
  'longitude': w.longitude,
  'timestamp': w.timestamp.toIso8601String(),
}).toList()
```

### 2. **Payload Maior**
- Push pode ser mais lento devido ao tamanho
- Considerar limit de 200 rotas por lote (vs 500 de outras entidades)
- Logs incluem contagem de waypoints totais

### 3. **Validação**
```dart
// Validar antes de enviar
if (model.waypoints.isEmpty) {
  throw Exception('Rota precisa ter pelo menos 1 waypoint');
}
```

## Verificação

### 1. Análise estática
```bash
flutter analyze
```

### 2. Teste manual (quando Supabase estiver configurado)

**Cenário 1: Push de rotas locais**
1. Adicionar 3 rotas localmente (offline)
2. Conectar à internet
3. Fazer pull-to-refresh
4. Verificar logs: "PUSH concluído: 3 rotas enviadas"
5. Checar Dashboard Supabase: 3 rotas devem aparecer

**Cenário 2: Pull de rotas remotas**
1. Criar rota no Dashboard Supabase
2. Fazer pull-to-refresh no app
3. Verificar logs: "PULL concluído: 1 rotas, X waypoints"
4. Rota aparece na lista do app

**Cenário 3: Convergência**
1. App A adiciona Rota X
2. App B adiciona Rota Y
3. Ambos fazem sync
4. Ambos devem ter Rotas X e Y

### 3. Logs esperados

```
[RunningRoutesProvider] Iniciando sync bidirecional...
[RunningRoutesRepositoryImplRemote] Iniciando PUSH de rotas locais...
[SupabaseRunningRoutesRemoteDatasource] upsertRunningRoutes: enviando 3 rotas
[SupabaseRunningRoutesRemoteDatasource] upsert response: 3 rotas confirmadas
[RunningRoutesRepositoryImplRemote] PUSH concluído: 3 rotas enviadas
[RunningRoutesRepositoryImplRemote] Iniciando PULL. lastSync=2025-12-01T10:30:00.000Z
[RunningRoutesRepositoryImplRemote] PULL concluído: 5 rotas, 27 waypoints
[RunningRoutesProvider] Sync concluído: 5 rotas totais
```

## Checklist de Erros Comuns

- ❌ **Waypoints não serializados corretamente**: Garantir conversão para JSONB
- ❌ **Push bloqueia pull**: Usar try/catch e continuar mesmo com erro
- ❌ **Sync apenas quando vazio**: SEMPRE chamar sync (push + pull)
- ❌ **RLS policy bloqueando upsert**: Verificar permissões no Supabase
- ❌ **Conflitos de timestamp**: Last-Write-Wins baseado em `updated_at`
- ❌ **UI não atualiza após sync**: Verificar `mounted` antes de `notifyListeners()`

## Estrutura da Tabela Supabase (Pendente)

```sql
CREATE TABLE running_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  waypoints JSONB NOT NULL, -- Array de {latitude, longitude, timestamp}
  featured BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger para updated_at automático
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON running_routes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS: acesso público (ou filtrar por user_id)
ALTER TABLE running_routes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public access" ON running_routes FOR ALL USING (true);
```

## Próximos Passos

### Após criar tabela Supabase:
1. ✅ Testar push de rotas locais
2. ✅ Testar pull de rotas remotas
3. ✅ Verificar convergência entre múltiplos clientes
4. ✅ Validar logs de debug

### Melhorias futuras (opcional):
- Flag "dirty" por rota para push seletivo
- IDs temporários com reconciliação após push
- Conflict resolution além de Last-Write-Wins
- Sync em background via WorkManager

## Referências

- `running_routes_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 12: `12_agent_list_refresh.md` (RefreshIndicator)
- Prompt 16: `16_running_route_entity_prompt.md` (Pull incremental)
- Prompt 17: `17_running_route_entity_prompt.md` (UI → Domínio)

## Estado Atual vs. Estado Final

**Antes (Prompt 17):**
- ✅ Pull incremental
- ❌ Push não implementado
- ❌ Rotas locais não vão pro servidor

**Depois (Prompt 18):**
- ✅ Push + Pull bidirecional
- ✅ Convergência entre clientes
- ✅ Rotas locais enviadas automaticamente
