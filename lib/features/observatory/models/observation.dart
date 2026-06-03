enum ObservationSeverity { actionRequired, inProgress, informative, closed }

enum ObservationActionType { uploadSupport, viewDetail, contactSupport, none }

class ObservationDashboard {
  const ObservationDashboard({
    required this.apprenticeId,
    required this.apprenticeName,
    required this.observations,
    required this.generatedAt,
  });

  factory ObservationDashboard.fromJson(Map<String, dynamic> json) {
    final apprentice = json['apprentice'] as Map<String, dynamic>? ?? {};
    final observationsJson = json['observations'] as List<dynamic>? ?? [];

    return ObservationDashboard(
      apprenticeId: (apprentice['id'] ?? '').toString(),
      apprenticeName: (apprentice['name'] ?? 'Aprendiz').toString(),
      generatedAt: _parseDateTime(json['generated_at']),
      observations: observationsJson
          .whereType<Map<String, dynamic>>()
          .map(Observation.fromJson)
          .where((observation) => observation.isActive)
          .toList(growable: false),
    );
  }

  final String apprenticeId;
  final String apprenticeName;
  final List<Observation> observations;
  final DateTime generatedAt;

  int get actionRequiredCount => observations
      .where(
        (observation) =>
            observation.severity == ObservationSeverity.actionRequired,
      )
      .length;

  int get inProgressCount => observations
      .where(
        (observation) => observation.severity == ObservationSeverity.inProgress,
      )
      .length;

  int get informativeCount => observations
      .where(
        (observation) =>
            observation.severity == ObservationSeverity.informative,
      )
      .length;

  Observation? get nextAction {
    final required = observations.where(
      (observation) =>
          observation.severity == ObservationSeverity.actionRequired,
    );

    if (required.isNotEmpty) {
      return required.first;
    }

    final actionable = observations.where(
      (observation) => observation.actionType != ObservationActionType.none,
    );

    return actionable.isEmpty ? null : actionable.first;
  }
}

class Observation {
  const Observation({
    required this.id,
    required this.apprenticeId,
    required this.title,
    required this.typeLabel,
    required this.area,
    required this.description,
    required this.date,
    required this.authorName,
    required this.statusLabel,
    required this.severity,
    required this.actionLabel,
    required this.actionType,
    required this.isActive,
    this.dueDate,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: (json['id'] ?? '').toString(),
      apprenticeId: (json['apprentice_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      typeLabel: (json['type_label'] ?? json['type'] ?? 'General').toString(),
      area: (json['area'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: _parseDateTime(json['date']),
      dueDate: json['due_date'] == null
          ? null
          : _parseDateTime(json['due_date']),
      authorName: (json['author_name'] ?? json['author'] ?? 'Instructor')
          .toString(),
      statusLabel: (json['status_label'] ?? '').toString(),
      severity: ObservationSeverityX.fromBackend(
        (json['severity'] ?? '').toString(),
      ),
      actionLabel: (json['action_label'] ?? '').toString(),
      actionType: ObservationActionTypeX.fromBackend(
        (json['action_type'] ?? '').toString(),
      ),
      isActive: json['active'] != false,
    );
  }

  final String id;
  final String apprenticeId;
  final String title;
  final String typeLabel;
  final String area;
  final String description;
  final DateTime date;
  final DateTime? dueDate;
  final String authorName;
  final String statusLabel;
  final ObservationSeverity severity;
  final String actionLabel;
  final ObservationActionType actionType;
  final bool isActive;
}

extension ObservationSeverityX on ObservationSeverity {
  static ObservationSeverity fromBackend(String value) {
    return switch (value) {
      'action_required' => ObservationSeverity.actionRequired,
      'in_progress' => ObservationSeverity.inProgress,
      'informative' => ObservationSeverity.informative,
      'closed' => ObservationSeverity.closed,
      _ => ObservationSeverity.informative,
    };
  }

  String get backendValue {
    return switch (this) {
      ObservationSeverity.actionRequired => 'action_required',
      ObservationSeverity.inProgress => 'in_progress',
      ObservationSeverity.informative => 'informative',
      ObservationSeverity.closed => 'closed',
    };
  }
}

extension ObservationActionTypeX on ObservationActionType {
  static ObservationActionType fromBackend(String value) {
    return switch (value) {
      'upload_support' => ObservationActionType.uploadSupport,
      'view_detail' => ObservationActionType.viewDetail,
      'contact_support' => ObservationActionType.contactSupport,
      'none' => ObservationActionType.none,
      _ => ObservationActionType.none,
    };
  }

  String get backendValue {
    return switch (this) {
      ObservationActionType.uploadSupport => 'upload_support',
      ObservationActionType.viewDetail => 'view_detail',
      ObservationActionType.contactSupport => 'contact_support',
      ObservationActionType.none => 'none',
    };
  }
}

DateTime _parseDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  return DateTime.now();
}
