# 18 - Sincronização Bidirecional: SafetyAlert (Push + Pull) - versão didática

> **Este prompt foi adaptado para fins didáticos. As alterações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug.**

## Resumo

Esta mudança implementa sincronização **bidirecional** para `SafetyAlert` entre o cache local (SharedPreferences) e o Supabase:
1. **Push**: Envia alertas locais para o servidor
2. **Pull**: Busca atualizações remotas desde o último sync

## Contexto do Projeto

**Status atual**: 
- ✅ Pull incremental já implementado (Prompt 16)
- ✅ Mapper centralizado com parsing de enum (Prompt 17)
- ⏳ Push para servidor **não implementado**
- ⏳ Tabela Supabase `safety_alerts` não criada

## Arquivos a serem modificados

### 1. `lib/features/alerts/infrastructure/remote/safety_alerts_remote_datasource_supabase.dart`

**Adicionar método de upsert:**
```dart
/// Envia lista de alertas para o Supabase (upsert em lote)
/// Retorna número de alertas confirmados pelo servidor
Future<int> upsertSafetyAlerts(List<SafetyAlertModel> models) async {
  try {
    if (kDebugMode) {
      print('[SupabaseSafetyAlertsRemoteDatasource] upsertSafetyAlerts: enviando ${models.length} alertas');
    }
    
    final data = models.map((m) => {
      'id': m.id,
      'description': m.description,
      'type': m.type, // String (snake_case)
      'severity': m.severity,
      'latitude': m.latitude,
      'longitude': m.longitude,
      'timestamp': m.timestamp.toIso8601String(),
      'updated_at': m.updatedAt.toIso8601String(),
    }).toList();
    
    final response = await _client
      .from('safety_alerts')
      .upsert(data)
      .select();
    
    if (kDebugMode) {
      print('[SupabaseSafetyAlertsRemoteDatasource] upsert response: ${response.length} alertas confirmados');
    }
    
    return response.length;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseSafetyAlertsRemoteDatasource] Erro no upsert: $e');
    }
    return 0; // Melhor esforço: erro não bloqueia pull
  }
}
```

### 2. `lib/features/alerts/infrastructure/repositories/safety_alerts_repository_impl_remote.dart`

**Atualizar método `syncFromServer()` para Push + Pull:**

```dart
@override
Future<int> syncFromServer() async {
  final startedAt = DateTime.now().toUtc();
  
  // === FASE 1: PUSH (melhor esforço) ===
  try {
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Iniciando PUSH de alertas locais...');
    }
    
    // Lê todos os alertas do cache local
    final localDtos = await _localDao.listAll();
    
    if (localDtos.isNotEmpty) {
      // Converte para models do Supabase
      final models = localDtos.map((dto) {
        final entity = _mapper.toEntity(dto);
        return SafetyAlertModel.fromEntity(entity);
      }).toList();
      
      // Envia para o servidor (upsert)
      final pushed = await _remote.upsertSafetyAlerts(models);
      
      if (kDebugMode) {
        print('[SafetyAlertsRepositoryImplRemote] PUSH concluído: $pushed alertas enviados');
      }
    }
  } catch (e) {
    // Erro no push não bloqueia o pull
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
    }
  }
  
  // === FASE 2: PULL (incremental desde lastSync) ===
  final lastSync = await _getLastSync();
  
  if (kDebugMode) {
    print('[SafetyAlertsRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
  }
  
  final page = await _remote.fetchSafetyAlerts(since: lastSync);
  final fetched = page.items;
  
  if (fetched.isEmpty) {
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] PULL: nenhum alerta novo/alterado.');
    }
    await _setLastSync(startedAt);
    return 0;
  }
  
  // Merge por ID
  final existingDtos = await _localDao.listAll();
  final existingById = {for (var d in existingDtos) d.id: d};
  
  int changes = 0;
  for (final model in fetched) {
    final entity = _modelToEntity(model);
    final dto = _mapper.toDto(entity, updatedAt: model.updatedAt);
    existingById[dto.id] = dto;
    changes++;
  }
  
  await _localDao.upsertAll(existingById.values.toList());
  
  if (kDebugMode) {
    print('[SafetyAlertsRepositoryImplRemote] PULL concluído: $changes alertas atualizados');
  }
  
  await _setLastSync(startedAt);
  return changes;
}
```

### 3. `lib/features/alerts/presentation/providers/safety_alerts_provider.dart`

**Garantir que sync seja chamado sempre:**

```dart
Future<void> loadAlerts() async {
  if (_isLoading) return;
  
  _isLoading = true;
  notifyListeners();
  
  try {
    // Carrega cache local primeiro (responsividade)
    if (kDebugMode) {
      print('[SafetyAlertsProvider] Carregando do cache...');
    }
    _alerts = await _repository.loadFromCache();
    notifyListeners(); // Atualiza UI imediatamente
    
    // Sync bidirecional: SEMPRE executa (push + pull)
    if (kDebugMode) {
      print('[SafetyAlertsProvider] Iniciando sync bidirecional...');
    }
    await _repository.syncFromServer();
    _alerts = await _repository.listAll();
    
    if (kDebugMode) {
      print('[SafetyAlertsProvider] Sync concluído: ${_alerts.length} alertas totais');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[SafetyAlertsProvider] Erro ao carregar: $e');
    }
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## Particularidades de SafetyAlert

### 1. **Conversão de Enum AlertType**
```dart
// Push: enum → string (snake_case) via SafetyAlertMapper
final dto = _mapper.toDto(entity, updatedAt: model.updatedAt);
// 'type' será 'pothole', 'no_lighting', 'suspicious_activity', 'other'

// Pull: string → enum (parsing robusto) via SafetyAlertMapper
final entity = _mapper.toEntity(dto);
// Aceita 'no_lighting', 'noLighting', 'nolighting'
```

### 2. **Coordenadas Geográficas**
```dart
// Incluir latitude e longitude no upsert
'latitude': m.latitude,
'longitude': m.longitude,
```

### 3. **Severidade (1-5)**
```dart
// Filtro de alertas em destaque
final featured = await _repository.listFeatured(); // severity >= 4
```

## Verificação

### 1. Análise estática
```bash
flutter analyze
```

### 2. Teste manual (quando Supabase estiver configurado)

**Cenário 1: Push de alertas locais**
1. Criar 3 alertas offline
2. Conectar à internet
3. Fazer pull-to-refresh
4. Verificar logs: "PUSH concluído: 3 alertas enviados"
5. Checar Dashboard: alertas aparecem com enum correto

**Cenário 2: Pull de alertas remotos**
1. Criar alerta no Dashboard com type='pothole'
2. Fazer pull-to-refresh no app
3. Alerta aparece com ícone de buraco

**Cenário 3: Enum persistence**
1. Criar alerta com type='no_lighting'
2. Verificar que persiste como 'no_lighting' (snake_case)
3. Verificar que lê corretamente como `AlertType.noLighting`

### 3. Logs esperados

```
[SafetyAlertsProvider] Iniciando sync bidirecional...
[SafetyAlertsRepositoryImplRemote] Iniciando PUSH de alertas locais...
[SupabaseSafetyAlertsRemoteDatasource] upsertSafetyAlerts: enviando 3 alertas
[SupabaseSafetyAlertsRemoteDatasource] upsert response: 3 alertas confirmados
[SafetyAlertsRepositoryImplRemote] PUSH concluído: 3 alertas enviados
[SafetyAlertsRepositoryImplRemote] Iniciando PULL. lastSync=2025-12-01T10:30:00.000Z
[SafetyAlertsRepositoryImplRemote] PULL concluído: 5 alertas atualizados
[SafetyAlertsProvider] Sync concluído: 5 alertas totais
```

## Checklist de Erros Comuns

- ❌ **Enum não converte corretamente**: Usar SafetyAlertMapper para conversão
- ❌ **Type em formato errado no Supabase**: Garantir snake_case (no_lighting)
- ❌ **Push bloqueia pull**: Usar try/catch e continuar
- ❌ **Coordenadas nulas**: Validar latitude/longitude antes de enviar
- ❌ **Severity fora do range**: Validar 1-5
- ❌ **RLS bloqueando upsert**: Verificar políticas

## Estrutura da Tabela Supabase (Pendente)

```sql
CREATE TABLE safety_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('pothole', 'no_lighting', 'suspicious_activity', 'other')),
  severity INTEGER NOT NULL CHECK (severity BETWEEN 1 AND 5),
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para busca geográfica (futuro)
CREATE INDEX idx_safety_alerts_location ON safety_alerts (latitude, longitude);

-- Índice para severidade
CREATE INDEX idx_safety_alerts_severity ON safety_alerts (severity DESC);

-- Trigger para updated_at
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON safety_alerts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS: acesso público
ALTER TABLE safety_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public access" ON safety_alerts FOR ALL USING (true);
```

## Próximos Passos

### Após criar tabela Supabase:
1. ✅ Testar push de alertas com diferentes tipos
2. ✅ Verificar conversão correta de enum
3. ✅ Testar filtro de severidade (≥ 4)
4. ✅ Validar coordenadas geográficas

### Melhorias futuras (opcional):
- Busca geográfica (alertas próximos)
- Notificações push para alertas de alta severidade
- Filtro de alertas por tipo
- Mapa de calor de alertas

## Referências

- `safety_alerts_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 16: `16_safety_alert_entity_prompt.md` (Pull incremental)
- Prompt 17: `17_safety_alert_entity_prompt.md` (Mapper + Enum)

## Estado Atual vs. Estado Final

**Antes (Prompt 17):**
- ✅ Pull incremental
- ✅ Enum parsing robusto
- ❌ Push não implementado

**Depois (Prompt 18):**
- ✅ Push + Pull bidirecional
- ✅ Enum persiste corretamente
- ✅ Alertas locais enviados automaticamente
