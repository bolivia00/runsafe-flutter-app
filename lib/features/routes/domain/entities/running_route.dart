import 'package:runsafe/features/routes/domain/entities/waypoint.dart';

class RunningRoute {
  final String id;
  final String name;
  final List<Waypoint> waypoints; // Lista de Entidades!

  RunningRoute({
    required this.id,
    required this.name,
    required this.waypoints,
  }) {
    if (waypoints.isEmpty) {
      throw ArgumentError('Rota precisa ter pelo menos um waypoint.');
    }
  }

  // Lógica de Domínio:
  double get totalDistanceInKm {
    // (Aqui entraria uma lógica complexa para calcular a distância
    // entre todos os waypoints, mas vamos simplificar por agora)
    return waypoints.length * 0.01; // Simulação
  }
}