// Remote datasource Supabase para SafetyAlert
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

class SafetyAlertModel {
  final String id;
  final String description;
  final String type; // Enum como string
  final DateTime timestamp;
  final int severity;
  final DateTime? updatedAt;

  SafetyAlertModel({
    required this.id,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.severity,
    required this.updatedAt,
  });

  factory SafetyAlertModel.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    try {
      ts = DateTime.parse(json['timestamp'] as String? ?? json['created_at'] as String).toUtc();
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

    int sev = 1;
    final sevRaw = json['severity'];
    if (sevRaw is int) {
      sev = sevRaw;
    } else if (sevRaw is String) {
      sev = int.tryParse(sevRaw) ?? 1;
    }
    sev = sev.clamp(1, 5);

    return SafetyAlertModel(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      timestamp: ts,
      severity: sev,
      updatedAt: upd,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'type': type, // String (snake_case)
        'severity': severity,
        'timestamp': timestamp.toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };
}

/// Datasource responsável por buscar alertas no Supabase.
class SupabaseSafetyAlertsRemoteDatasource {
  final SupabaseClient _client;
  static const String _table = 'safety_alerts';

  SupabaseSafetyAlertsRemoteDatasource(this._client);

  /// Busca alertas com suporte a filtro incremental (updated_at >= since) e paginação via offset.
  /// limit default 500 (registros mais simples que rotas).
  Future<RemotePage<SafetyAlertModel>> fetchSafetyAlerts({
    DateTime? since,
    int limit = 500,
    PageCursor? cursor,
  }) async {
    final effectiveCursor = cursor ?? PageCursor(offset: 0, limit: limit);

    if (kDebugMode) {
      print('[SupabaseSafetyAlertsRemoteDatasource] Fetch: since=${since?.toIso8601String() ?? 'null'}, limit=$limit, offset=${effectiveCursor.offset}');
    }

    final builder = _client
        .from(_table)
        .select('id,description,type,timestamp,created_at,severity,updated_at');

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
        print('[SupabaseSafetyAlertsRemoteDatasource] Erro ao buscar alertas: $e');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    final models = data
        .whereType<Map<String, dynamic>>()
        .map((row) => SafetyAlertModel.fromJson(row))
        .toList();

    if (models.isEmpty) {
      if (kDebugMode) {
        print('[SupabaseSafetyAlertsRemoteDatasource] Página vazia (offset=${effectiveCursor.offset}).');
      }
      return const RemotePage(items: [], nextCursor: null);
    }

    if (kDebugMode) {
      final highSeverity = models.where((m) => m.severity >= 4).length;
      print('[SupabaseSafetyAlertsRemoteDatasource] Fetched ${models.length} alertas; alta severidade (>=4)=$highSeverity');
    }

    // Se retornou menos que limit -> fim
    final hasMore = models.length == effectiveCursor.limit;
    final next = hasMore ? effectiveCursor.next(models.length) : null;

    return RemotePage(items: models, nextCursor: next);
  }

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
        'timestamp': m.timestamp.toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();
      
      final response = await _client
        .from(_table)
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
}
