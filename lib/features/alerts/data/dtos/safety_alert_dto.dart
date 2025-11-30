// ignore_for_file: non_constant_identifier_names

class SafetyAlertDto {
  final String id;
  final String description;
  final String type;
  final int severity;
  final String createdAt;
  final String updatedAt;

  SafetyAlertDto({
    required this.id,
    required this.description,
    required this.type,
    required this.severity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyAlertDto.fromJson(Map<String, dynamic> json) {
    return SafetyAlertDto(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'other',
      severity: json['severity'] is int ? json['severity'] : int.tryParse(json['severity'].toString()) ?? 1,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type': type,
      'severity': severity,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
  
  Map<String, dynamic> toSupabaseJson() {
    return {
      'description': description,
      'type': type,
      'severity': severity,
      'created_at': createdAt,
      'updated_at': DateTime.now().toIso8601String(), 
    };
  }
}