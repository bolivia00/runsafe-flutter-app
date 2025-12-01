// Remote datasource Supabase para Waypoint
// Referências internas: ver `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md` para dicas de setup/RLS.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class WaypointModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final DateTime? updatedAt;

  WaypointModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.updatedAt,
  });

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = DateTime.parse(json['timestamp'] as String).toUtc();
    } catch (_) {
      ts = DateTime.now().toUtc();
    }

    DateTime? upd;
    final updRaw = json['updated_at'];
    if (updRaw is String) {
      try {
        upd = DateTime.parse(updRaw).toUtc();
      } catch (_) {}
    }

    return WaypointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: ts,
      updatedAt: upd,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(), // PK e ID único
        'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

  /// Gera ID único baseado em timestamp ISO (usado como chave)
  String get id => timestamp.toIso8601String();
}

/// Datasource responsável por buscar waypoints no Supabase.
class SupabaseWaypointsRemoteDatasource {
  final SupabaseClient _client;
  static const String _table = 'waypoints';

  SupabaseWaypointsRemoteDatasource(this._client);

  /// Busca waypoints com suporte a filtro incremental (updated_at >= since) e paginação via offset.
  /// limit default 500 (registros simples).
  Future<RemotePage<WaypointModel>> fetchWaypoints({
    DateTime? since,
    int limit = 500,
    PageCursor? cursor,
  }) async {
    final effectiveCursor = cursor ?? PageCursor(offset: 0, limit: limit);

    if (kDebugMode) {
      print('[SupabaseWaypointsRemoteDatasource] Fetch: since=${since?.toIso8601String() ?? 'null'}, limit=$limit, offset=${effectiveCursor.offset}');
    }

    final builder = _client
        .from(_table)
        .select('latitude,longitude,timestamp,updated_at');

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
        print('[SupabaseWaypointsRemoteDatasource] Erro ao buscar waypoints: $e');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    final models = data
        .whereType<Map<String, dynamic>>()
        .map((row) => WaypointModel.fromJson(row))
        .toList();

    if (models.isEmpty) {
      if (kDebugMode) {
        print('[SupabaseWaypointsRemoteDatasource] Página vazia (offset=${effectiveCursor.offset}).');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    if (kDebugMode) {
      print('[SupabaseWaypointsRemoteDatasource] Fetched ${models.length} waypoints');
    }

    // Se retornou menos que limit -> fim
    final hasMore = models.length == effectiveCursor.limit;
    final next = hasMore ? effectiveCursor.next(models.length) : null;

    return RemotePage(items: models, nextCursor: next);
  }

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
        .from(_table)
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
}
