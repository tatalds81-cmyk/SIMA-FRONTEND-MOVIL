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
    final apprentice = _firstMap([
      json['apprentice'],
      json['aprendiz'],
      json['usuario'],
      json['user'],
    ]);
    final observationsJson =
        _firstList([
          json['observations'],
          json['observaciones'],
          json['items'],
          json['registros'],
        ]) ??
        const [];

    return ObservationDashboard(
      apprenticeId: _firstString([
        apprentice['id'],
        apprentice['id_aprendiz'],
        apprentice['id_usuario'],
      ]),
      apprenticeName: _firstString([
        apprentice['name'],
        apprentice['nombre_completo'],
        apprentice['nombre'],
        'Aprendiz',
      ]),
      generatedAt: _parseDateTime(
        _firstValue([json['generated_at'], json['fecha_generacion']]),
      ),
      observations: observationsJson
          .whereType<Map<String, dynamic>>()
          .map(Observation.fromJson)
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
    final typeLabel = _firstString([
      json['type_label'],
      json['tipo_label'],
      json['tipo_observacion'],
      json['tipo'],
      json['categoria'],
      'General',
    ]);
    final statusLabel = _firstString([
      json['status_label'],
      json['estado_label'],
      json['estado'],
      json['estado_observacion'],
    ]);
    final actionType = ObservationActionTypeX.fromBackend(
      _firstString([json['action_type'], json['tipo_accion'], json['accion']]),
    );

    return Observation(
      id: _firstString([json['id'], json['id_observacion']]),
      apprenticeId: _firstString([
        json['apprentice_id'],
        json['id_aprendiz'],
        json['aprendiz_id'],
      ]),
      title: _firstString([
        json['title'],
        json['titulo'],
        json['asunto'],
        typeLabel,
      ]),
      typeLabel: typeLabel,
      area: _firstString([
        json['area'],
        json['dependencia'],
        json['fuente'],
        json['modulo'],
        json['grupo'],
      ]),
      description: _firstString([
        json['description'],
        json['descripcion'],
        json['observacion'],
        json['detalle'],
      ]),
      date: _parseDateTime(
        _firstValue([
          json['date'],
          json['fecha'],
          json['fecha_observacion'],
          json['created_at'],
        ]),
      ),
      dueDate:
          _firstValue([
                json['due_date'],
                json['fecha_limite'],
                json['fecha_vencimiento'],
              ]) ==
              null
          ? null
          : _parseDateTime(
              _firstValue([
                json['due_date'],
                json['fecha_limite'],
                json['fecha_vencimiento'],
              ]),
            ),
      authorName: _firstString([
        json['author_name'],
        json['author'],
        json['autor'],
        json['registrado_por'],
        json['instructor'],
        'Instructor',
      ]),
      statusLabel: statusLabel,
      severity: ObservationSeverityX.fromBackend(
        _firstString([
          json['severity'],
          json['severidad'],
          json['prioridad'],
          statusLabel,
        ]),
      ),
      actionLabel: _firstString([
        json['action_label'],
        json['accion_label'],
        json['label_accion'],
        actionType.defaultLabel,
      ]),
      actionType: actionType,
      isActive: _isActive(json, statusLabel),
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
    final normalized = value.toLowerCase().trim();
    return switch (normalized) {
      'action_required' ||
      'requiere_respuesta' ||
      'requiere respuesta' ||
      'alta' ||
      'grave' ||
      'pendiente' => ObservationSeverity.actionRequired,
      'in_progress' ||
      'en seguimiento' ||
      'en_seguimiento' ||
      'media' ||
      'proceso' => ObservationSeverity.inProgress,
      'informative' ||
      'informativa' ||
      'baja' ||
      'info' => ObservationSeverity.informative,
      'closed' ||
      'cerrada' ||
      'cerrado' ||
      'resuelta' ||
      'resuelto' => ObservationSeverity.closed,
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
    final normalized = value.toLowerCase().trim();
    return switch (normalized) {
      'upload_support' ||
      'subir_soporte' ||
      'enviar_soporte' ||
      'soporte' => ObservationActionType.uploadSupport,
      'view_detail' ||
      'ver_detalle' ||
      'detalle' => ObservationActionType.viewDetail,
      'contact_support' ||
      'contactar' ||
      'bienestar' => ObservationActionType.contactSupport,
      'none' || 'ninguna' || '' => ObservationActionType.none,
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

  String get defaultLabel {
    return switch (this) {
      ObservationActionType.uploadSupport => 'Enviar soporte',
      ObservationActionType.viewDetail => 'Ver detalle',
      ObservationActionType.contactSupport => 'Contactar',
      ObservationActionType.none => 'Ver detalle',
    };
  }
}

Object? _firstValue(List<Object?> values) {
  for (final value in values) {
    if (value != null) {
      return value;
    }
  }
  return null;
}

Map<String, dynamic> _firstMap(List<Object?> values) {
  for (final value in values) {
    if (value is Map<String, dynamic>) {
      return value;
    }
  }
  return const {};
}

List<dynamic>? _firstList(List<Object?> values) {
  for (final value in values) {
    if (value is List<dynamic>) {
      return value;
    }
  }
  return null;
}

String _firstString(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    if (value is Map<String, dynamic>) {
      final firstName = value['nombres']?.toString().trim() ?? '';
      final lastName = value['apellidos']?.toString().trim() ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        return fullName;
      }

      final nested = _firstString([
        value['nombre_completo'],
        value['nombre'],
        value['name'],
        value['label'],
        value['descripcion'],
        value['numero_ficha'],
        value['persona'],
        value['usuario'],
      ]);
      if (nested.isNotEmpty) {
        return nested;
      }
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

bool _isActive(Map<String, dynamic> json, String statusLabel) {
  final explicit = _firstValue([json['active'], json['activo']]);
  if (explicit is bool) {
    return explicit;
  }

  final normalized = statusLabel.toLowerCase().trim();
  return normalized != 'cerrada' &&
      normalized != 'cerrado' &&
      normalized != 'resuelta' &&
      normalized != 'resuelto';
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
