import 'package:uuid/uuid.dart';

class WeeklyGoal {
  // --- CAMPOS ADICIONADOS ---
  final String id;
  final String userId; // No futuro, isso viria do seu ProfileRepository

  final double targetKm;
  double currentKm;

  // --- CONSTRUTOR ATUALIZADO ---
  WeeklyGoal({
    String? id, // O ID agora é opcional na criação
    this.userId = 'default-user', // Um valor padrão por enquanto
    required this.targetKm,
    this.currentKm = 0.0,
  })  : id = id ?? const Uuid().v4(), // Se nenhum ID for passado, gera um novo
        assert(targetKm > 0, 'A meta de KMs deve ser maior que zero.'),
        assert(currentKm >= 0, 'O progresso atual não pode ser negativo');

  // LÓGICA DE DOMÍNIO (igual a antes)
  double get progressPercentage {
    if (targetKm == 0) return 0.0;
    return (currentKm / targetKm).clamp(0.0, 1.0);
  }

  void addRun(double km) {
    if (km < 0) return;
    currentKm += km;
  }
}