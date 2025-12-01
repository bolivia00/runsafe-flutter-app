# 18 - Sincronização Bidirecional: WeeklyGoal (Push + Pull) - versão didática

> **Este prompt foi adaptado para fins didáticos. As alterações devem conter comentários explicativos, dicas práticas, checklist de erros comuns, exemplos de logs esperados e referências aos arquivos de debug.**

## Resumo

Esta mudança implementa sincronização **bidirecional** para `WeeklyGoal` entre o cache local (SharedPreferences) e o Supabase:
1. **Push**: Envia metas locais para o servidor
2. **Pull**: Busca atualizações remotas desde o último sync

## Contexto do Projeto

**Status atual**: 
- ✅ Repositório local implementado (`WeeklyGoalsRepositoryImpl`)
- ✅ Model como Mapper híbrido (Prompt 17)
- ⏳ Repository remoto **não implementado** ainda
- ⏳ Push para servidor **não implementado**
- ⏳ Tabela Supabase `weekly_goals` não criada

## Arquivos a serem criados/modificados

### 1. **CRIAR** `lib/features/goals/infrastructure/remote/weekly_goals_remote_datasource_supabase.dart`

Este arquivo já existe parcialmente. **Adicionar método de upsert:**

```dart
/// Envia lista de metas para o Supabase (upsert em lote)
/// Retorna número de metas confirmadas pelo servidor
Future<int> upsertWeeklyGoals(List<WeeklyGoalModel> models) async {
  try {
    if (kDebugMode) {
      print('[SupabaseWeeklyGoalsRemoteDatasource] upsertWeeklyGoals: enviando ${models.length} metas');
    }
    
    final data = models.map((m) => {
      'id': m.id,
      'user_id': m.userId,
      'target_km': m.targetKm,
      'current_km': m.currentKm,
      'week_start': _calculateWeekStart(DateTime.now()).toIso8601String(),
      'week_end': _calculateWeekEnd(DateTime.now()).toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).toList();
    
    final response = await _client
      .from('weekly_goals')
      .upsert(data)
      .select();
    
    if (kDebugMode) {
      print('[SupabaseWeeklyGoalsRemoteDatasource] upsert response: ${response.length} metas confirmadas');
    }
    
    return response.length;
  } catch (e) {
    if (kDebugMode) {
      print('[SupabaseWeeklyGoalsRemoteDatasource] Erro no upsert: $e');
    }
    return 0; // Melhor esforço: erro não bloqueia pull
  }
}

// Métodos auxiliares para calcular semana
DateTime _calculateWeekStart(DateTime date) {
  final weekday = date.weekday;
  return date.subtract(Duration(days: weekday - 1)).toUtc();
}

DateTime _calculateWeekEnd(DateTime date) {
  final weekday = date.weekday;
  return date.add(Duration(days: 7 - weekday)).toUtc();
}
```

### 2. **CRIAR** `lib/features/goals/infrastructure/repositories/weekly_goals_repository_impl_remote.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runsafe/features/goals/domain/repositories/weekly_goals_repository.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/infrastructure/remote/weekly_goals_remote_datasource_supabase.dart';
import 'package:runsafe/features/goals/data/models/weekly_goal_model.dart';

class WeeklyGoalsRepositoryImplRemote implements WeeklyGoalsRepository {
  final WeeklyGoalsLocalDao _localDao;
  final SupabaseWeeklyGoalsRemoteDatasource _remote;
  final String _defaultUserId;
  static const String _lastSyncKey = 'weekly_goals_last_sync_v1';

  WeeklyGoalsRepositoryImplRemote(
    this._localDao,
    this._remote,
    {String defaultUserId = 'default-user'}
  ) : _defaultUserId = defaultUserId;

  Future<DateTime?> _getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  Future<void> _setLastSync(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, dt.toUtc().toIso8601String());
  }

  @override
  Future<List<WeeklyGoal>> loadFromCache() async {
    return await _localDao.loadAllForUser(_defaultUserId);
  }

  @override
  Future<int> syncFromServer() async {
    final startedAt = DateTime.now().toUtc();
    
    // === FASE 1: PUSH (melhor esforço) ===
    try {
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] Iniciando PUSH de metas locais...');
      }
      
      // Lê todas as metas do usuário do cache local
      final localGoals = await _localDao.loadAllForUser(_defaultUserId);
      
      if (localGoals.isNotEmpty) {
        // Converte para models
        final models = localGoals.map((goal) => WeeklyGoalModel.fromEntity(goal)).toList();
        
        // Envia para o servidor (upsert)
        final pushed = await _remote.upsertWeeklyGoals(models);
        
        if (kDebugMode) {
          print('[WeeklyGoalsRepositoryImplRemote] PUSH concluído: $pushed metas enviadas');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia o pull
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    // === FASE 2: PULL (incremental desde lastSync) ===
    final lastSync = await _getLastSync();
    
    if (kDebugMode) {
      print('[WeeklyGoalsRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
    }
    
    final page = await _remote.fetchWeeklyGoals(since: lastSync);
    final fetched = page.items;
    
    if (fetched.isEmpty) {
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] PULL: nenhuma meta nova/alterada.');
      }
      await _setLastSync(startedAt);
      return 0;
    }
    
    // Salvar metas atualizadas
    int changes = 0;
    for (final model in fetched) {
      final entity = model.toEntity();
      await _localDao.save(entity);
      changes++;
    }
    
    if (kDebugMode) {
      print('[WeeklyGoalsRepositoryImplRemote] PULL concluído: $changes metas atualizadas');
    }
    
    await _setLastSync(startedAt);
    return changes;
  }

  @override
  Future<List<WeeklyGoal>> listAll() async {
    return await loadFromCache();
  }

  @override
  Future<List<WeeklyGoal>> listFeatured() async {
    final all = await loadFromCache();
    // Featured: metas iniciadas mas não completas (0 < progress < 1)
    return all.where((g) {
      final progress = g.progressPercentage;
      return progress > 0 && progress < 1.0;
    }).toList();
  }

  @override
  Future<WeeklyGoal?> getById(String id) async {
    final all = await loadFromCache();
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}
```

### 3. **Atualizar** `lib/features/goals/presentation/providers/weekly_goals_provider.dart`

```dart
Future<void> load(String userId) async {
  if (_loading) return;
  
  _loading = true;
  _currentUserId = userId;
  notifyListeners();
  
  try {
    // Carrega cache local primeiro (responsividade)
    if (kDebugMode) {
      print('[WeeklyGoalsProvider] Carregando do cache para userId=$userId...');
    }
    _items = await _repository.loadFromCache();
    notifyListeners(); // Atualiza UI imediatamente
    
    // Sync bidirecional: SEMPRE executa (push + pull)
    if (kDebugMode) {
      print('[WeeklyGoalsProvider] Iniciando sync bidirecional...');
    }
    final changes = await _repository.syncFromServer();
    _items = await _repository.listAll();
    
    if (kDebugMode) {
      print('[WeeklyGoalsProvider] Sync concluído: ${_items.length} metas ($changes mudanças)');
    }
    
    _error = null;
  } catch (e) {
    _error = e.toString();
    if (kDebugMode) {
      print('[WeeklyGoalsProvider] Erro ao carregar: $e');
    }
  } finally {
    _loading = false;
    notifyListeners();
  }
}
```

### 4. **Atualizar** `lib/main.dart`

```dart
// Substituir WeeklyGoalsRepositoryImpl por WeeklyGoalsRepositoryImplRemote
ChangeNotifierProvider(
  create: (context) => WeeklyGoalsProvider(
    WeeklyGoalsRepositoryImplRemote(
      WeeklyGoalsLocalDao(StorageService()),
      SupabaseWeeklyGoalsRemoteDatasource(Supabase.instance.client),
    ),
  )..load('default-user'),
),
```

## Particularidades de WeeklyGoal

### 1. **Lógica de Negócio na Entidade**
```dart
// addRun() atualiza currentKm
goal.addRun(5.2); // Adiciona 5.2 km à meta
final progress = goal.progressPercentage; // Getter calculado
```

### 2. **Filtro por Usuário**
```dart
// Push e pull filtram por user_id
'user_id': m.userId, // 'default-user' por padrão
```

### 3. **Featured: Metas em Progresso**
```dart
// Metas com 0 < progress < 1 (iniciadas mas não completas)
return all.where((g) => g.progressPercentage > 0 && g.progressPercentage < 1.0);
```

### 4. **Week Start/End**
```dart
// Calcular semana atual (segunda a domingo)
'week_start': _calculateWeekStart(DateTime.now()),
'week_end': _calculateWeekEnd(DateTime.now()),
```

## Verificação

### 1. Análise estática
```bash
flutter analyze
```

### 2. Teste manual (quando Supabase estiver configurado)

**Cenário 1: Push de metas locais**
1. Criar 2 metas offline
2. Adicionar progresso (5 km em cada)
3. Conectar à internet
4. Fazer pull-to-refresh
5. Verificar logs: "PUSH concluído: 2 metas enviadas"
6. Checar Dashboard: metas com progresso correto

**Cenário 2: Pull de metas remotas**
1. Criar meta no Dashboard com target_km=20, current_km=10
2. Fazer pull-to-refresh no app
3. Meta aparece com 50% de progresso

**Cenário 3: Convergência multi-usuário**
1. App A (user1) cria Meta X
2. App B (user2) cria Meta Y
3. Cada usuário vê apenas suas próprias metas

### 3. Logs esperados

```
[WeeklyGoalsProvider] Iniciando sync bidirecional...
[WeeklyGoalsRepositoryImplRemote] Iniciando PUSH de metas locais...
[SupabaseWeeklyGoalsRemoteDatasource] upsertWeeklyGoals: enviando 2 metas
[SupabaseWeeklyGoalsRemoteDatasource] upsert response: 2 metas confirmadas
[WeeklyGoalsRepositoryImplRemote] PUSH concluído: 2 metas enviadas
[WeeklyGoalsRepositoryImplRemote] Iniciando PULL. lastSync=2025-12-01T10:30:00.000Z
[WeeklyGoalsRepositoryImplRemote] PULL concluído: 3 metas atualizadas
[WeeklyGoalsProvider] Sync concluído: 3 metas (3 mudanças)
```

## Checklist de Erros Comuns

- ❌ **Metas de outros usuários aparecem**: Filtrar por user_id no RLS
- ❌ **Progress não atualiza**: Usar `addRun()` da entidade
- ❌ **Week_start/week_end incorretos**: Calcular baseado em segunda-feira
- ❌ **Push bloqueia pull**: Try/catch no push
- ❌ **currentKm > targetKm**: Permitido, mas progress fica >= 100%
- ❌ **RLS bloqueando upsert**: Verificar política para user_id

## Estrutura da Tabela Supabase (Pendente)

```sql
CREATE TABLE weekly_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL, -- Filtrar por usuário
  target_km DOUBLE PRECISION NOT NULL CHECK (target_km > 0),
  current_km DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (current_km >= 0),
  week_start DATE NOT NULL,
  week_end DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para busca por usuário
CREATE INDEX idx_weekly_goals_user ON weekly_goals (user_id);

-- Índice para busca por semana
CREATE INDEX idx_weekly_goals_week ON weekly_goals (week_start, week_end);

-- Trigger para updated_at
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON weekly_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS: cada usuário vê apenas suas metas
ALTER TABLE weekly_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own goals" ON weekly_goals
  FOR ALL
  USING (user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Política temporária para testes (user_id = 'default-user')
CREATE POLICY "Default user access" ON weekly_goals
  FOR ALL
  USING (user_id = 'default-user');
```

## Próximos Passos

### Após criar tabela Supabase:
1. ✅ Criar `WeeklyGoalsRepositoryImplRemote`
2. ✅ Testar push de metas locais
3. ✅ Testar pull de metas remotas
4. ✅ Verificar filtro por user_id
5. ✅ Testar featured (metas em progresso)

### Melhorias futuras (opcional):
- Histórico de metas por semana
- Notificações para metas próximas de completar
- Gráfico de progresso semanal
- Desafios entre usuários

## Referências

- `weekly_goals_cache_debug_prompt.md`
- `supabase_init_debug_prompt.md`
- `supabase_rls_remediation.md`
- Prompt 16: `16_weekly_goal_entity_prompt.md` (Provider local)
- Prompt 17: `17_weekly_goal_entity_prompt.md` (Model híbrido)

## Estado Atual vs. Estado Final

**Antes (Prompt 17):**
- ✅ Repository local implementado
- ✅ Model como Mapper + DTO
- ❌ Sem sincronização remota

**Depois (Prompt 18):**
- ✅ Repository remoto criado
- ✅ Push + Pull bidirecional
- ✅ Filtro por user_id
- ✅ Metas locais enviadas automaticamente

## Observação Importante

WeeklyGoal é a **única entidade** que ainda não tem repository remoto implementado. Este prompt cria toda a infraestrutura necessária:
- ✅ Datasource remoto (já existe parcialmente)
- ✅ Repository remoto (novo arquivo)
- ✅ Integração no provider
- ✅ Atualização no main.dart
