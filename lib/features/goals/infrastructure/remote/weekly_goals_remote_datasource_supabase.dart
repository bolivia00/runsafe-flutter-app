// Remote datasource Supabase para WeeklyGoal
// Referências internas: ver `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md` para dicas de setup/RLS.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:runsafe/features/goals/data/models/weekly_goal_model.dart';

/// Cursor simples baseado em offset
class PageCursor {
  final int offset;
  final int limit;
  const PageCursor({required this.offset, required this.limit});

  PageCursor next(int fetchedCount) => PageCursor(offset: offset + fetchedCount, limit: limit);
}

/// Página remota genérica
class RemotePage<T> {
  final List<T> items;
  final PageCursor? nextCursor;
  const RemotePage({required this.items, this.nextCursor});
}

/// Datasource responsável por buscar metas semanais no Supabase.
class SupabaseWeeklyGoalsRemoteDatasource {
  final SupabaseClient _client;
  static const String _table = 'weekly_goals';

  SupabaseWeeklyGoalsRemoteDatasource(this._client);

  /// Busca metas com suporte a filtro incremental (updated_at >= since) e paginação via offset.
  /// limit default 500 (registros simples).
  /// 
  /// Campos esperados na tabela Supabase:
  /// - id (text/uuid)
  /// - user_id (text) -> mapeia para userId
  /// - target_km (numeric/double)
  /// - current_km (numeric/double)
  /// - updated_at (timestamptz)
  Future<RemotePage<WeeklyGoalModel>> fetchWeeklyGoals({
    DateTime? since,
    int limit = 500,
    PageCursor? cursor,
  }) async {
    final effectiveCursor = cursor ?? PageCursor(offset: 0, limit: limit);

    if (kDebugMode) {
      print('[SupabaseWeeklyGoalsRemoteDatasource] Fetch: since=${since?.toIso8601String() ?? 'null'}, limit=$limit, offset=${effectiveCursor.offset}');
    }

    final builder = _client
        .from(_table)
        .select('id,user_id,target_km,current_km,updated_at');

    if (since != null) {
      builder.gte('updated_at', since.toUtc().toIso8601String());
    }

    builder.order('updated_at', ascending: true)
        .range(effectiveCursor.offset, effectiveCursor.offset + effectiveCursor.limit - 1);

    List<dynamic> data;
    try {
      final dataRaw = await builder;
      data = dataRaw as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('[SupabaseWeeklyGoalsRemoteDatasource] Erro ao buscar metas: $e');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    final models = data
        .whereType<Map<String, dynamic>>()
        .map((row) => _fromSupabaseJson(row))
        .toList();

    if (models.isEmpty) {
      if (kDebugMode) {
        print('[SupabaseWeeklyGoalsRemoteDatasource] Página vazia (offset=${effectiveCursor.offset}).');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    if (kDebugMode) {
      final inProgress = models.where((m) => m.currentKm > 0 && m.currentKm < m.targetKm).length;
      print('[SupabaseWeeklyGoalsRemoteDatasource] Fetched ${models.length} metas; em progresso=$inProgress');
    }

    // Se retornou menos que limit -> fim
    final hasMore = models.length == effectiveCursor.limit;
    final next = hasMore ? effectiveCursor.next(models.length) : null;

    return RemotePage(items: models, nextCursor: next);
  }

  /// Envia lista de metas para o Supabase (upsert em lote)
  /// Retorna número de metas confirmadas pelo servidor
  Future<int> upsertWeeklyGoals(List<WeeklyGoalModel> models) async {
    try {
      if (kDebugMode) {
        print('[SupabaseWeeklyGoalsRemoteDatasource] upsertWeeklyGoals: enviando ${models.length} metas');
      }
      
      final data = models.map((m) => {
        'id': m.id,
        'user_id': m.userId, // snake_case para Supabase
        'target_km': m.targetKm,
        'current_km': m.currentKm,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();
      
      final response = await _client
        .from(_table)
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

  /// Converte row do Supabase para WeeklyGoalModel
  /// Mapeia user_id -> userId, target_km -> targetKm, current_km -> currentKm
  WeeklyGoalModel _fromSupabaseJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetKm: (json['target_km'] as num).toDouble(),
      currentKm: (json['current_km'] as num).toDouble(),
    );
  }
}

// Bloco de uso (exemplo):
/*
final datasource = SupabaseWeeklyGoalsRemoteDatasource(Supabase.instance.client);
final page = await datasource.fetchWeeklyGoals(since: lastSyncDate);
for (final model in page.items) {
  final entity = model.toEntity();
  await localDao.save(entity);
}
*/

// Checklist de erros comuns:
// - Campo user_id vs userId: usar snake_case no Supabase, camelCase no Dart
// - target_km/current_km podem vir como int: usar (json['x'] as num).toDouble()
// - updated_at pode estar ausente: tratar defensivamente no repositório
// - Paginação: verificar hasMore corretamente (length == limit)
