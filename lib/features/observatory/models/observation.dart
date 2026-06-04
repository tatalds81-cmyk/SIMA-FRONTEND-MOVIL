class ObservatoryFilters {
  const ObservatoryFilters({
    this.fechaDesde,
    this.fechaHasta,
    this.severidad,
    this.tipo,
    this.estado,
  });

  final DateTime? fechaDesde;
  final DateTime? fechaHasta;
  final String? severidad;
  final String? tipo;
  final String? estado;

  ObservatoryFilters copyWith({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? severidad,
    String? tipo,
    String? estado,
    bool clearFechaDesde = false,
    bool clearFechaHasta = false,
    bool clearSeveridad = false,
    bool clearTipo = false,
    bool clearEstado = false,
  }) {
    return ObservatoryFilters(
      fechaDesde: clearFechaDesde ? null : fechaDesde ?? this.fechaDesde,
      fechaHasta: clearFechaHasta ? null : fechaHasta ?? this.fechaHasta,
      severidad: clearSeveridad ? null : severidad ?? this.severidad,
      tipo: clearTipo ? null : tipo ?? this.tipo,
      estado: clearEstado ? null : estado ?? this.estado,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (fechaDesde != null) {
      params['fecha_desde'] = _isoDate(fechaDesde!);
    }
    if (fechaHasta != null) {
      params['fecha_hasta'] = _isoDate(fechaHasta!);
    }
    if (_hasText(severidad)) {
      params['severidad'] = severidad!.trim();
    }
    if (_hasText(tipo)) {
      params['tipo'] = tipo!.trim();
    }
    if (_hasText(estado)) {
      params['estado'] = estado!.trim();
    }
    return params;
  }
}

class ObservatoryMetrics {
  const ObservatoryMetrics({
    required this.total,
    required this.abiertas,
    required this.cerradas,
    required this.alta,
    required this.media,
    required this.baja,
  });

  factory ObservatoryMetrics.fromJson(Map<String, dynamic>? json) {
    final porEstado = _firstMap([json?['por_estado'], json?['estado']]);
    final porSeveridad = _firstMap([
      json?['por_severidad'],
      json?['severidad'],
    ]);

    return ObservatoryMetrics(
      total: _toInt(json?['total']),
      abiertas: _toInt(porEstado['ABIERTA']),
      cerradas: _toInt(porEstado['CERRADA']),
      alta: _toInt(porSeveridad['GRAVE']) + _toInt(porSeveridad['CRITICA']),
      media: _toInt(porSeveridad['MODERADA']),
      baja: _toInt(porSeveridad['LEVE']),
    );
  }

  final int total;
  final int abiertas;
  final int cerradas;
  final int alta;
  final int media;
  final int baja;
}

class ObservatoryObservationResponse {
  const ObservatoryObservationResponse({
    required this.metrics,
    required this.items,
    required this.message,
  });

  factory ObservatoryObservationResponse.fromJson(Map<String, dynamic> json) {
    final items = _firstList([
      json['observaciones'],
      json['observations'],
      json['items'],
    ]);

    return ObservatoryObservationResponse(
      metrics: ObservatoryMetrics.fromJson(
        _firstMap([json['metricas'], json['metrics']]),
      ),
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ObservatoryObservation.fromJson)
          .toList(growable: false),
      message: _firstString([
        json['mensaje'],
        json['message'],
        'No tienes observaciones por el momento',
      ]),
    );
  }

  final ObservatoryMetrics metrics;
  final List<ObservatoryObservation> items;
  final String message;
}

class ObservatoryAlertResponse {
  const ObservatoryAlertResponse({
    required this.metrics,
    required this.items,
    required this.message,
  });

  factory ObservatoryAlertResponse.fromJson(Map<String, dynamic> json) {
    final items = _firstList([json['alertas'], json['alerts'], json['items']]);

    return ObservatoryAlertResponse(
      metrics: ObservatoryMetrics.fromJson(
        _firstMap([json['metricas'], json['metrics']]),
      ),
      items: items
          .whereType<Map<String, dynamic>>()
          .map(ObservatoryAlert.fromJson)
          .toList(growable: false),
      message: _firstString([
        json['mensaje'],
        json['message'],
        'No tienes alertas por el momento',
      ]),
    );
  }

  final ObservatoryMetrics metrics;
  final List<ObservatoryAlert> items;
  final String message;
}

class ObservatoryObservation {
  const ObservatoryObservation({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.severidad,
    required this.estado,
    required this.descripcion,
    required this.responsableNombre,
    required this.responsableRol,
  });

  factory ObservatoryObservation.fromJson(Map<String, dynamic> json) {
    final responsable = _firstMap([json['responsable']]);
    return ObservatoryObservation(
      id: _firstString([json['id_observacion'], json['id']]),
      fecha: _parseDate(_firstValue([json['fecha'], json['fecha_observacion']])),
      tipo: _firstString([json['tipo'], json['tipo_observacion'], 'General']),
      severidad: _firstString([json['severidad'], 'LEVE']),
      estado: _firstString([json['estado'], 'ABIERTA']),
      descripcion: _firstString([json['descripcion'], json['detalle']]),
      responsableNombre: _firstString([
        responsable['nombre_completo'],
        responsable['nombre'],
        'Sin responsable',
      ]),
      responsableRol: _firstString([responsable['rol'], 'responsable']),
    );
  }

  final String id;
  final DateTime fecha;
  final String tipo;
  final String severidad;
  final String estado;
  final String descripcion;
  final String responsableNombre;
  final String responsableRol;
}

class ObservatoryAlert {
  const ObservatoryAlert({
    required this.id,
    required this.tipo,
    required this.severidad,
    required this.estado,
    required this.origen,
    required this.reglaDisparo,
    required this.descripcion,
    required this.fechaAlerta,
    required this.fechaCierre,
    required this.justificacionCierre,
    required this.fechaReapertura,
    required this.justificacionReapertura,
    required this.responsableNombre,
    required this.responsableRol,
    required this.responsableCierreNombre,
    required this.responsableCierreRol,
    required this.responsableReaperturaNombre,
    required this.responsableReaperturaRol,
  });

  factory ObservatoryAlert.fromJson(Map<String, dynamic> json) {
    final responsable = _firstMap([json['responsable']]);
    final cierre = _firstMap([json['responsable_cierre']]);
    final reapertura = _firstMap([json['responsable_reapertura']]);

    return ObservatoryAlert(
      id: _firstString([json['id_alerta'], json['id']]),
      tipo: _firstString([json['tipo'], json['tipo_alerta'], 'General']),
      severidad: _firstString([json['severidad'], 'LEVE']),
      estado: _firstString([json['estado'], 'ABIERTA']),
      origen: _firstString([json['origen'], 'Sin origen']),
      reglaDisparo: _firstString([json['regla_disparo']]),
      descripcion: _firstString([json['descripcion'], json['detalle']]),
      fechaAlerta: _parseDate(_firstValue([json['fecha_alerta'], json['fecha']])),
      fechaCierre: _parseNullableDate(json['fecha_cierre']),
      justificacionCierre: _firstString([json['justificacion_cierre']]),
      fechaReapertura: _parseNullableDate(json['fecha_reapertura']),
      justificacionReapertura: _firstString([
        json['justificacion_reapertura'],
      ]),
      responsableNombre: _firstString([
        responsable['nombre_completo'],
        responsable['nombre'],
        'Sin responsable',
      ]),
      responsableRol: _firstString([responsable['rol'], 'responsable']),
      responsableCierreNombre: _firstString([
        cierre['nombre_completo'],
        cierre['nombre'],
      ]),
      responsableCierreRol: _firstString([cierre['rol']]),
      responsableReaperturaNombre: _firstString([
        reapertura['nombre_completo'],
        reapertura['nombre'],
      ]),
      responsableReaperturaRol: _firstString([reapertura['rol']]),
    );
  }

  final String id;
  final String tipo;
  final String severidad;
  final String estado;
  final String origen;
  final String reglaDisparo;
  final String descripcion;
  final DateTime fechaAlerta;
  final DateTime? fechaCierre;
  final String justificacionCierre;
  final DateTime? fechaReapertura;
  final String justificacionReapertura;
  final String responsableNombre;
  final String responsableRol;
  final String responsableCierreNombre;
  final String responsableCierreRol;
  final String responsableReaperturaNombre;
  final String responsableReaperturaRol;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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

List<dynamic> _firstList(List<Object?> values) {
  for (final value in values) {
    if (value is List<dynamic>) {
      return value;
    }
  }
  return const [];
}

String _firstString(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return '';
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _parseDate(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

DateTime? _parseNullableDate(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
