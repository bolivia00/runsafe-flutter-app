# 18 - Sincronização Bidirecional: Waypoint (Push + Pull) - versão didática

> **Este prompt foi adaptado para fins didáticos. As alterações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug.**

## Resumo

Esta mudança implementa sincronização **bidirecional** para `Waypoint` entre o cache local (SharedPreferences) e o Supabase:
1. **Push**: Envia waypoints locais para o servidor
2. **Pull**: Busca atualizações remotas desde o último sync

## Contexto do Projeto

**Status atual**: 
- ✅ Pull incremental já implementado (Prompt 16)
- ✅ Mapper com parsing defensivo de timestamp (Prompt 17)
- ⏳ Push para servidor **não implementado**
- ⏳ Tabela Supabase `waypoints` não criada

## Arquivos a serem modificados

### 1. `lib/features/routes/infrastructure/remote/waypoints_remote_datasource_supabase.dart`

**Adicionar método de upsert:**
```dart
/// Envia lista de waypoints para o Supabase (upsert em lote)
/// Retorna número de waypoints confirmados pelo servidor
Future<int> upsertWaypoints(List<WaypointModel> models) async {
  try {
    if (kDebugMode) {
      print('[SupabaseWaypointsRemoteDatasource] upsertWaypoints: enviando ${models.length} waypoints');
    }
    
    final data = models.map((m) => {
      'latitude': m.latitude,
      'longitude': m.longitude,
      'timestamp': m.timestamp.toIso8601String(), // PK e ID único
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).toList();
    
    final response = await _client
      .from('waypoints')
      .upsert(data, onConflict: 'timestamp') // timestamp é a PK
      .select();
    
    if (kDebugMode) {
      print('[SupabaseWaypointsRemoteDatasource] upsert response: ${response.length} waypoints confirmados');
    }
    
    return response.length;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseWaypointsRemoteDatasource] Erro no upsert: $e');
    }
    return 0; // Melhor esforço: erro não bloqueia pull
  }
}
```

### 2. `lib/features/routes/infrastructure/repositories/waypoints_repository_impl_remote.dart`

**Atualizar método `syncFromServer()` para Push + Pull:**

```dart
@override
Future<int> syncFromServer() async {
  final startedAt = DateTime.now().toUtc();
  
  // === FASE 1: PUSH (melhor esforço) ===
  try {
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Iniciando PUSH de waypoints locais...');
    }
    
    // Lê todos os waypoints do cache local
    final localDtos = await _localDao.listAll();
    
    if (localDtos.isNotEmpty) {
      // Converte para models do Supabase
      final models = localDtos.map((dto) {
        final entity = _mapper.toEntity(dto);
        return WaypointModel.fromEntity(entity);
      }).toList();
      
      // Envia para o servidor (upsert)
      final pushed = await _remote.upsertWaypoints(models);
      
      if (kDebugMode) {
        print('[WaypointsRepositoryImplRemote] PUSH concluído: $pushed waypoints enviados');
      }
    }
  } catch (e) {
    // Erro no push não bloqueia o pull
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
    }
  }
  
  // === FASE 2: PULL (incremental desde lastSync) ===
  final lastSync = await _getLastSync();
  
  if (kDebugMode) {
    print('[WaypointsRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
  }
  
  final page = await _remote.fetchWaypoints(since: lastSync);
  final fetched = page.items;
  
  if (fetched.isEmpty) {
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] PULL: nenhum waypoint novo/alterado.');
    }
    await _setLastSync(startedAt);
    return 0;
  }
  
  // Merge por ID (timestamp ISO)
  final existingDtos = await _localDao.listAll();
  final existingById = {for (var d in existingDtos) d.ts: d};
  
  int changes = 0;
  for (final model in fetched) {
    final entity = _modelToEntity(model);
    final dto = _mapper.toDto(entity);
    existingById[dto.ts] = dto;
    changes++;
  }
  
  await _localDao.upsertAll(existingById.values.toList());
  
  if (kDebugMode) {
    print('[WaypointsRepositoryImplRemote] PULL concluído: $changes waypoints atualizados');
  }
  
  await _setLastSync(startedAt);
  return changes;
}
```

### 3. `lib/features/routes/presentation/providers/waypoints_provider.dart`

**Garantir que sync seja chamado sempre:**

```dart
Future<void> loadWaypoints() async {
  if (_isLoading) return;
  
  _isLoading = true;
  notifyListeners();
  
  try {
    // Carrega cache local primeiro (responsividade)
    if (kDebugMode) {
      print('[WaypointsProvider] Carregando do cache...');
    }
    _waypoints = await _repository.loadFromCache();
    notifyListeners(); // Atualiza UI imediatamente
    
    // Sync bidirecional: SEMPRE executa (push + pull)
    if (kDebugMode) {
      print('[WaypointsProvider] Iniciando sync bidirecional...');
    }
    await _repository.syncFromServer();
    _waypoints = await _repository.listAll();
    
    if (kDebugMode) {
      print('[WaypointsProvider] Sync concluído: ${_waypoints.length} waypoints totais');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[WaypointsProvider] Erro ao carregar: $e');
    }
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## Particularidades de Waypoint

### 1. **Timestamp como Chave Primária**
```dart
// Upsert usa timestamp como identificador único
.upsert(data, onConflict: 'timestamp')

// Merge usa timestamp ISO como chave
final existingById = {for (var d in existingDtos) d.ts: d};
```

### 2. **Formato ISO 8601**
```dart
// Push: DateTime → String ISO (via WaypointMapper)
'timestamp': m.timestamp.toIso8601String()

// Pull: String ISO → DateTime (parsing defensivo)
final entity = _mapper.toEntity(dto); // tryParse com fallback
```

### 3. **Precisão de Coordenadas**
```dart
// Garantir precisão decimal (6-8 casas)
'latitude': m.latitude,  // ex: -23.550520
'longitude': m.longitude, // ex: -46.633308
```

### 4. **Featured (10 mais recentes)**
```dart
// Após sync, calcular featured localmente
@override
Future<List<Waypoint>> listFeatured() async {
  final all = await loadFromCache();
  all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return all.take(10).toList();
}
```

## Verificação

### 1. Análise estática
```bash
flutter analyze
```

### 2. Teste manual (quando Supabase estiver configurado)

**Cenário 1: Push de waypoints locais**
1. Criar 5 waypoints offline
2. Conectar à internet
3. Fazer pull-to-refresh
4. Verificar logs: "PUSH concluído: 5 waypoints enviados"
5. Checar Dashboard: waypoints com timestamps corretos

**Cenário 2: Pull de waypoints remotos**
1. Criar waypoint no Dashboard
2. Fazer pull-to-refresh no app
3. Waypoint aparece na lista

**Cenário 3: Conflito de timestamp**
1. Dois clientes criam waypoint no mesmo timestamp (raro)
2. Last-Write-Wins: último a fazer push vence

### 3. Logs esperados

```
[WaypointsProvider] Iniciando sync bidirecional...
[WaypointsRepositoryImplRemote] Iniciando PUSH de waypoints locais...
[SupabaseWaypointsRemoteDatasource] upsertWaypoints: enviando 5 waypoints
[SupabaseWaypointsRemoteDatasource] upsert response: 5 waypoints confirmados
[WaypointsRepositoryImplRemote] PUSH concluído: 5 waypoints enviados
[WaypointsRepositoryImplRemote] Iniciando PULL. lastSync=2025-12-01T10:30:00.000Z
[WaypointsRepositoryImplRemote] PULL concluído: 8 waypoints atualizados
[WaypointsProvider] Sync concluído: 8 waypoints totais
```

## Checklist de Erros Comuns

- ❌ **Timestamp parsing falha**: WaypointMapper já tem tryParse com fallback
- ❌ **Conflito de PK**: Usar `onConflict: 'timestamp'` no upsert
- ❌ **Timestamp duplicado**: Raro, mas possível; Last-Write-Wins
- ❌ **Timezone inconsistente**: Sempre usar UTC (.toUtc())
- ❌ **Push bloqueia pull**: Try/catch no push, continuar no pull
- ❌ **Coordenadas imprecisas**: Usar double precision no Postgres

## Estrutura da Tabela Supabase (Pendente)

```sql
CREATE TABLE waypoints (
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  timestamp TIMESTAMPTZ PRIMARY KEY, -- Timestamp como PK única
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para busca por timestamp (range queries)
CREATE INDEX idx_waypoints_timestamp ON waypoints (timestamp DESC);

-- Índice geográfico (futuro)
CREATE INDEX idx_waypoints_location ON waypoints (latitude, longitude);

-- Trigger para updated_at
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON waypoints
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS: acesso público
ALTER TABLE waypoints ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public access" ON waypoints FOR ALL USING (true);
```

## Próximos Passos

### Após criar tabela Supabase:
1. ✅ Testar push de waypoints locais
2. ✅ Verificar timestamps no formato ISO 8601
3. ✅ Testar featured (10 mais recentes)
4. ✅ Validar precisão de coordenadas

### Melhorias futuras (opcional):
- Busca geográfica (waypoints próximos)
- Agrupamento por rota
- Filtro por intervalo de datas
- Exportação GPX/KML

## Referências

- `waypoints_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- ISO 8601: https://en.wikipedia.org/wiki/ISO_8601
- Prompt 16: `16_waypoint_entity_prompt.md` (Pull incremental)
- Prompt 17: `17_waypoint_entity_prompt.md` (Mapper + Timestamp)

## Estado Atual vs. Estado Final

**Antes (Prompt 17):**
- ✅ Pull incremental
- ✅ Timestamp parsing defensivo
- ❌ Push não implementado

**Depois (Prompt 18):**
- ✅ Push + Pull bidirecional
- ✅ Timestamp como ID único
- ✅ Waypoints locais enviados automaticamente
