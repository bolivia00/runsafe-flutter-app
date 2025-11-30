import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:runsafe/features/alerts/data/dtos/safety_alert_dto.dart';

class SafetyAlertRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  // Busca lista do Supabase
  Future<List<SafetyAlertDto>> fetchAlerts() async {
    try {
      final response = await _client
          .from('safety_alerts')
          .select()
          .order('created_at');
      
      // O Supabase retorna uma lista de Maps
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => SafetyAlertDto.fromJson(json)).toList();
    } catch (e) {
      // Se der erro (ex: sem internet), retorna lista vazia ou lança erro
      // Aqui vamos lançar para o Repositório tratar
      throw Exception('Erro Supabase: $e');
    }
  }

  // Envia novo alerta para o Supabase
  Future<SafetyAlertDto> addAlert(SafetyAlertDto dto) async {
    final response = await _client
        .from('safety_alerts')
        .insert(dto.toSupabaseJson()) // Usa o JSON sem ID
        .select()
        .single(); // Pede o item criado de volta

    return SafetyAlertDto.fromJson(response);
  }

  // Deleta alerta no Supabase
  Future<void> deleteAlert(String id) async {
    await _client.from('safety_alerts').delete().eq('id', id);
  }
}