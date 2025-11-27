// Enum para nosso "tipo forte"
enum AlertType { pothole, noLighting, suspiciousActivity, other }

class SafetyAlert {
  final String id;
  final String description;
  final AlertType type;
  final DateTime timestamp; // Tipo forte
  final int severity; // Invariante (1-5)

  SafetyAlert({
    required this.id,
    required this.description,
    required this.type,
    required this.timestamp,
    this.severity = 1,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('ID não pode ser vazio');
    }
    if (severity < 1 || severity > 5) {
      throw ArgumentError('Severidade deve ser entre 1 e 5');
    }
  }
}