// ignore_for_file: non_constant_identifier_names
class SafetyAlertDto {
  final String alert_id;
  final String description;
  final String alert_type; // Fiel ao backend (String)
  final String timestamp; // Fiel ao backend (String ISO 8601)
  final int severity;

  SafetyAlertDto({
    required this.alert_id,
    required this.description,
    required this.alert_type,
    required this.timestamp,
    required this.severity,
  });

  factory SafetyAlertDto.fromJson(Map<String, dynamic> json) {
    return SafetyAlertDto(
      alert_id: json['alert_id'] as String,
      description: json['description'] as String,
      alert_type: json['alert_type'] as String,
      timestamp: json['timestamp'] as String,
      severity: json['severity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_id': alert_id,
      'description': description,
      'alert_type': alert_type,
      'timestamp': timestamp,
      'severity': severity,
    };
  }
}