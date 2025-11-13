// Esta é a nossa classe "limpa" de domínio.
class WeeklyGoal {
  final double targetKm;
  double currentKm;

  // INVARIANTE: Garantimos que a entidade nunca será criada em um estado inválido.
  WeeklyGoal({required this.targetKm, this.currentKm = 0.0}) {
    if (targetKm <= 0) {
      throw ArgumentError('A meta de KMs deve ser maior que zero.');
    }
    if (currentKm < 0) {
      throw ArgumentError('O progresso atual não pode ser negativo.');
    }
  }

  // LÓGICA DE DOMÍNIO: A entidade sabe calcular seu próprio progresso.
  double get progressPercentage {
    if (targetKm == 0) return 0.0;
    return (currentKm / targetKm).clamp(0.0, 1.0); // Retorna de 0.0 a 1.0 (0% a 100%)
  }

  void addRun(double km) {
    if (km < 0) return;
    currentKm += km;
  }
}