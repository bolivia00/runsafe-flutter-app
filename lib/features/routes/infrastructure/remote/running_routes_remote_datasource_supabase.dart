// Remote datasource Supabase para RunningRoute
// Referências internas: ver `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md` para dicas de setup/RLS.
// Este arquivo foca em FETCH + paginação simples + filtro incremental.

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

  WaypointModel({required this.latitude, required this.longitude, required this.timestamp});

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      timestamp: _parseTs(json['ts']),
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    try {
      return DateTime.parse(v as String).toUtc();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
  }

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'ts': timestamp.toIso8601String(),
      };
}

class RunningRouteModel {
  final String id;
  final String name;
  final List<WaypointModel> waypoints;
  final DateTime? updatedAt; // Pode ser null se não vier do servidor

  RunningRouteModel({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.updatedAt,
  });

  factory RunningRouteModel.fromJson(Map<String, dynamic> json) {
    final rawWaypoints = json['waypoints'];
    List<WaypointModel> wpList = [];
    if (rawWaypoints is List) {
      wpList = rawWaypoints
          .whereType<Map<String, dynamic>>()
          .map((e) => WaypointModel.fromJson(e))
          .toList();
    }
    DateTime? upd;
    final updRaw = json['updated_at'];
    if (updRaw is String) {
      try { upd = DateTime.parse(updRaw).toUtc(); } catch (_) {}
    }
    return RunningRouteModel(
      id: (json['id'] ?? json['route_id']) as String,
      name: (json['name'] ?? json['route_name']) as String,
      waypoints: wpList,
      updatedAt: upd,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };
}

/// Datasource responsável por buscar rotas no Supabase.
class SupabaseRunningRoutesRemoteDatasource {
  final SupabaseClient _client;
  static const String _table = 'running_routes';

  SupabaseRunningRoutesRemoteDatasource(this._client);

  /// Busca rotas com suporte a filtro incremental (updated_at >= since) e paginação via offset.
  /// limit default 200 devido ao payload (lista de waypoints).
  Future<RemotePage<RunningRouteModel>> fetchRunningRoutes({
    DateTime? since,
    int limit = 200,
    PageCursor? cursor,
  }) async {
    final effectiveCursor = cursor ?? PageCursor(offset: 0, limit: limit);

    final builder = _client
        .from(_table)
        .select('id,name,waypoints,updated_at');

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
        print('[SupabaseRunningRoutesRemoteDatasource] Erro ao buscar rotas: $e');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    final models = data
        .whereType<Map<String, dynamic>>()
        .map((row) => RunningRouteModel.fromJson(row))
        .toList();

    if (models.isEmpty) {
      if (kDebugMode) {
        print('[SupabaseRunningRoutesRemoteDatasource] Página vazia (offset=${effectiveCursor.offset}).');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    if (kDebugMode) {
      final waypointCounts = models.map((m) => m.waypoints.length).toList();
      final avg = waypointCounts.isEmpty
          ? 0
          : waypointCounts.reduce((a, b) => a + b) / waypointCounts.length;
      print('[SupabaseRunningRoutesRemoteDatasource] Fetched ${models.length} rotas; média waypoints=${avg.toStringAsFixed(2)}');
    }

    // Se retornou menos que limit -> fim
    final hasMore = models.length == effectiveCursor.limit;
    final next = hasMore ? effectiveCursor.next(models.length) : null;

    return RemotePage(items: models, nextCursor: next);
  }

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
          'lat': w.latitude,
          'lon': w.longitude,
          'ts': w.timestamp.toIso8601String(),
        }).toList(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();
      
      final response = await _client
        .from(_table)
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
}
