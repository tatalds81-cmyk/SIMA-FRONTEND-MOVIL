import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sima_movil_froned/features/profile/models/apprentice_profile.dart';
import 'package:sima_movil_froned/services/api_config.dart';
import 'package:sima_movil_froned/services/auth_service.dart';

abstract class ProfileRepository {
  Future<ApprenticeProfile> fetchCurrentApprenticeProfile();

  Future<ApprenticeProfile> updatePersonalInformation(
    ApprenticeProfile profile,
  );

  Future<EmergencyContact> updateEmergencyContact(EmergencyContact contact);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<String> updateProfilePhoto({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<ApprenticeProfile> fetchCurrentApprenticeProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return ApprenticeProfile.fromJson(_mockProfileResponse);
  }

  @override
  Future<ApprenticeProfile> updatePersonalInformation(
    ApprenticeProfile profile,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return profile;
  }

  @override
  Future<EmergencyContact> updateEmergencyContact(
    EmergencyContact contact,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return contact;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  @override
  Future<String> updateProfilePhoto({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return '';
  }
}

class BackendProfileRepository implements ProfileRepository {
  const BackendProfileRepository();

  @override
  Future<ApprenticeProfile> fetchCurrentApprenticeProfile() async {
    final profileData = await _tryGetMap(ApiConfig.profileOverview);
    final sessionsData = await _tryGetMap(ApiConfig.sessions);
    final authData = await _tryGetMap(ApiConfig.me);
    final dashboardData = await _tryGetMap(ApiConfig.apprenticeDashboard);

    if (profileData.isEmpty &&
        sessionsData.isEmpty &&
        authData.isEmpty &&
        dashboardData.isEmpty &&
        AuthService.currentUser == null) {
      final token = AuthService.currentToken;
      if (token == null || token.isEmpty) {
        throw Exception(
          'No hay sesion activa. Inicia sesion nuevamente para cargar tu perfil.',
        );
      }
      throw Exception('No se recibieron datos del perfil desde el backend.');
    }

    return ApprenticeProfile.fromJson(
      _normalizeProfileResponse(
        profileData: profileData,
        userData: authData,
        sessionsData: sessionsData,
        authData: authData,
        dashboardData: dashboardData,
        currentUser: AuthService.currentUser,
      ),
    );
  }

  @override
  Future<ApprenticeProfile> updatePersonalInformation(
    ApprenticeProfile profile,
  ) async {
    await _sendJson(
      method: 'PUT',
      url: ApiConfig.profileOverview,
      payload: {'email': profile.email, 'telefono': profile.phone},
    );

    return profile;
  }

  @override
  Future<EmergencyContact> updateEmergencyContact(
    EmergencyContact contact,
  ) async {
    await _sendJson(
      method: 'PUT',
      url: ApiConfig.profileOverview,
      payload: {
        'contacto_emergencia': {
          'nombre': contact.name,
          'parentesco': contact.relationship,
          'telefono': contact.phone,
          'correo': contact.email,
        },
        'emergency_contact': contact.toJson(),
        'nombre_contacto_emergencia': contact.name,
        'parentesco_contacto_emergencia': contact.relationship,
        'telefono_contacto_emergencia': contact.phone,
        'correo_contacto_emergencia': contact.email,
      },
    );

    return contact;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _sendJson(
      method: 'PUT',
      url: ApiConfig.profileOverview,
      payload: {
        'password_actual': currentPassword,
        'password_nuevo': newPassword,
      },
    );
  }

  @override
  Future<String> updateProfilePhoto({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final data = await _sendMultipartImage(
      url: ApiConfig.profilePhoto,
      fieldName: 'foto',
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );

    final photoUrl = _firstString([
      data['foto_perfil_url'],
      data['photo_url'],
      data['url'],
    ]);

    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      final persona = Map<String, dynamic>.from(
        currentUser['persona'] as Map? ?? const {},
      );
      persona['foto_perfil_url'] = photoUrl;
      currentUser['persona'] = persona;
      currentUser['foto_perfil_url'] = photoUrl;
    }

    return photoUrl;
  }
}

Future<Map<String, dynamic>> _sendMultipartImage({
  required String url,
  required String fieldName,
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final token = AuthService.currentToken;
  if (token == null || token.isEmpty) {
    throw Exception(
      'No hay sesion activa. Por favor, inicia sesion nuevamente.',
    );
  }

  final mediaParts = mimeType.split('/');
  final request = http.MultipartRequest('PATCH', Uri.parse(url))
    ..headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    })
    ..files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: fileName,
        contentType: mediaParts.length == 2
            ? MediaType(mediaParts[0], mediaParts[1])
            : null,
      ),
    );

  final streamed = await request.send().timeout(const Duration(seconds: 30));
  final response = await http.Response.fromStream(streamed);
  return _decodeResponse(response);
}

Future<Map<String, dynamic>> _getMap(String url) {
  return _sendJson(method: 'GET', url: url);
}

Future<Map<String, dynamic>> _tryGetMap(String url) async {
  try {
    return await _getMap(url);
  } catch (_) {
    return const {};
  }
}

Future<Map<String, dynamic>> _sendJson({
  required String method,
  required String url,
  Map<String, dynamic>? payload,
}) async {
  final token = AuthService.currentToken;
  if (token == null || token.isEmpty) {
    throw Exception(
      'No hay sesion activa. Por favor, inicia sesion nuevamente.',
    );
  }

  final uri = Uri.parse(url);
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  try {
    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15));
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: jsonEncode(payload ?? const {}))
            .timeout(const Duration(seconds: 15));
      default:
        throw Exception('Metodo HTTP no soportado: $method');
    }

    return _decodeResponse(response);
  } on Exception catch (e) {
    final rawMessage = e.toString();
    final cleanMessage = rawMessage.startsWith('Exception: ')
        ? rawMessage.replaceFirst('Exception: ', '')
        : 'Error de red al conectar con el servidor.';
    throw Exception(cleanMessage);
  }
}

Map<String, dynamic> _decodeResponse(http.Response response) {
  if (response.statusCode == 204) {
    return const {};
  }

  Map<String, dynamic> body;
  try {
    body = jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return const {};
    }
    throw Exception('El servidor devolvio una respuesta inesperada.');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (body['ok'] == false) {
      throw Exception(body['message'] ?? 'Error desconocido del servidor');
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return body;
  }

  throw Exception(body['message'] ?? 'Error ${response.statusCode}');
}

Map<String, dynamic> _normalizeProfileResponse({
  required Map<String, dynamic> profileData,
  required Map<String, dynamic> userData,
  required Map<String, dynamic> sessionsData,
  required Map<String, dynamic> authData,
  required Map<String, dynamic> dashboardData,
  required Map<String, dynamic>? currentUser,
}) {
  final sessionUser = currentUser ?? const <String, dynamic>{};
  final roleInfo = _firstMap([
    profileData['informacion_rol'],
    profileData['informacionRol'],
  ]);
  final apprentice = _firstMap([
    profileData['aprendiz'],
    profileData['apprentice'],
    profileData['aprendiz_actual'],
    profileData['current_apprentice'],
    userData['aprendiz'],
    userData['apprentice'],
    authData['aprendiz'],
    authData['apprentice'],
    dashboardData['aprendiz'],
    dashboardData['apprentice'],
    profileData,
  ]);
  final user = _firstMap([
    profileData['usuario'],
    profileData['user'],
    profileData['persona'],
    profileData['datos_personales'],
    profileData['datosPersonales'],
    apprentice['usuario'],
    apprentice['user'],
    apprentice['persona'],
    userData['usuario'],
    userData['user'],
    userData['persona'],
    userData['datos_personales'],
    userData['datosPersonales'],
    authData['usuario'],
    authData['user'],
    authData['persona'],
    dashboardData['usuario'],
    dashboardData['user'],
    userData,
    sessionUser,
  ]);
  final ficha = _firstMap([
    profileData['ficha'],
    apprentice['ficha'],
    sessionsData['ficha'],
    dashboardData['ficha'],
    sessionsData['ficha'],
  ]);
  final program = _firstMap([
    profileData['programa'],
    apprentice['programa'],
    ficha['programa'],
    dashboardData['programa'],
  ]);
  final activeSession = _firstMap([
    sessionsData['sesion_activa'],
    profileData['sesion_activa'],
    dashboardData['sesion_activa'],
  ]);
  final emergencyContact = _firstMap([
    profileData['contacto_emergencia'],
    profileData['emergency_contact'],
    apprentice['contacto_emergencia'],
    apprentice['emergency_contact'],
    user['contacto_emergencia'],
    user['emergency_contact'],
    userData['contacto_emergencia'],
    userData['emergency_contact'],
  ]);

  final fullName = _firstString([
    apprentice['nombre_completo'],
    apprentice['nombreCompleto'],
    apprentice['full_name'],
    apprentice['name'],
    apprentice['nombre_usuario'],
    apprentice['nombreUsuario'],
    user['nombre_completo'],
    user['nombreCompleto'],
    user['full_name'],
    user['name'],
    user['nombre_usuario'],
    user['nombreUsuario'],
    sessionUser['nombre_completo'],
    sessionUser['nombreCompleto'],
    sessionUser['full_name'],
    sessionUser['name'],
    sessionUser['nombre_usuario'],
    sessionUser['nombreUsuario'],
    profileData['nombre_completo'],
    userData['nombre_completo'],
  ]);
  var firstName = _firstString([
    apprentice['first_name'],
    apprentice['firstName'],
    apprentice['nombres'],
    apprentice['nombre'],
    apprentice['primer_nombre'],
    apprentice['primerNombre'],
    apprentice['nombre1'],
    user['first_name'],
    user['firstName'],
    user['nombres'],
    user['nombre'],
    user['primer_nombre'],
    user['primerNombre'],
    user['nombre1'],
    sessionUser['first_name'],
    sessionUser['firstName'],
    sessionUser['nombres'],
    sessionUser['nombre'],
    sessionUser['primer_nombre'],
    sessionUser['primerNombre'],
    sessionUser['nombre1'],
  ]);
  var lastName = _firstString([
    apprentice['last_name'],
    apprentice['lastName'],
    apprentice['apellidos'],
    apprentice['apellido'],
    apprentice['primer_apellido'],
    apprentice['primerApellido'],
    apprentice['apellido1'],
    user['last_name'],
    user['lastName'],
    user['apellidos'],
    user['apellido'],
    user['primer_apellido'],
    user['primerApellido'],
    user['apellido1'],
    sessionUser['last_name'],
    sessionUser['lastName'],
    sessionUser['apellidos'],
    sessionUser['apellido'],
    sessionUser['primer_apellido'],
    sessionUser['primerApellido'],
    sessionUser['apellido1'],
  ]);

  if (firstName.isEmpty && fullName.isNotEmpty) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    firstName = parts.first;
    lastName = parts.skip(1).join(' ');
  }
  if (lastName.isEmpty && firstName.contains(' ')) {
    final parts = firstName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    firstName = parts.first;
    lastName = parts.skip(1).join(' ');
  }

  final startTime = _firstString([
    activeSession['hora_inicio_programada'],
    activeSession['hora_inicio'],
  ]);
  final endTime = _firstString([
    activeSession['hora_fin_programada'],
    activeSession['hora_fin'],
  ]);
  final sessionSchedule = startTime.isNotEmpty && endTime.isNotEmpty
      ? '${_shortTime(startTime)} - ${_shortTime(endTime)}'
      : '';

  return {
    'id': _firstString([
      apprentice['id'],
      apprentice['id_aprendiz'],
      user['id'],
      user['id_usuario'],
      sessionUser['id'],
      sessionUser['id_usuario'],
    ]),
    'first_name': firstName,
    'last_name': lastName,
    'document_type': _firstString([
      apprentice['document_type'],
      apprentice['documentType'],
      apprentice['tipo_documento'],
      apprentice['tipoDocumento'],
      apprentice['tipo_identificacion'],
      apprentice['tipoIdentificacion'],
      user['document_type'],
      user['documentType'],
      user['tipo_documento'],
      user['tipoDocumento'],
      user['tipo_identificacion'],
      user['tipoIdentificacion'],
      sessionUser['document_type'],
      sessionUser['documentType'],
      sessionUser['tipo_documento'],
      sessionUser['tipoDocumento'],
      sessionUser['tipo_identificacion'],
      sessionUser['tipoIdentificacion'],
    ]),
    'document_number': _firstString([
      apprentice['document_number'],
      apprentice['documentNumber'],
      apprentice['numero_documento'],
      apprentice['numeroDocumento'],
      apprentice['documento'],
      apprentice['identificacion'],
      apprentice['numero_identificacion'],
      apprentice['numeroIdentificacion'],
      apprentice['num_documento'],
      apprentice['nro_documento'],
      user['document_number'],
      user['documentNumber'],
      user['numero_documento'],
      user['numeroDocumento'],
      user['documento'],
      user['identificacion'],
      user['numero_identificacion'],
      user['numeroIdentificacion'],
      user['num_documento'],
      user['nro_documento'],
      sessionUser['document_number'],
      sessionUser['documentNumber'],
      sessionUser['numero_documento'],
      sessionUser['numeroDocumento'],
      sessionUser['documento'],
      sessionUser['identificacion'],
      sessionUser['numero_identificacion'],
      sessionUser['numeroIdentificacion'],
      sessionUser['num_documento'],
      sessionUser['nro_documento'],
    ]),
    'email': _firstString([
      profileData['email'],
      apprentice['email'],
      apprentice['correo'],
      apprentice['correo_electronico'],
      apprentice['correoElectronico'],
      apprentice['email_institucional'],
      apprentice['correo_institucional'],
      user['email'],
      user['correo'],
      user['correo_electronico'],
      user['correoElectronico'],
      user['email_institucional'],
      user['correo_institucional'],
      sessionUser['email'],
      sessionUser['correo'],
      sessionUser['correo_electronico'],
      sessionUser['correoElectronico'],
      sessionUser['email_institucional'],
      sessionUser['correo_institucional'],
    ]),
    'phone': _firstString([
      apprentice['phone'],
      apprentice['phone_number'],
      apprentice['telefono'],
      apprentice['celular'],
      apprentice['telefono_celular'],
      apprentice['numero_celular'],
      user['phone'],
      user['phone_number'],
      user['telefono'],
      user['celular'],
      user['telefono_celular'],
      user['numero_celular'],
      sessionUser['phone'],
      sessionUser['phone_number'],
      sessionUser['telefono'],
      sessionUser['celular'],
      sessionUser['telefono_celular'],
      sessionUser['numero_celular'],
    ]),
    'program': _firstString([
      program['nombre_programa'],
      program['nombrePrograma'],
      program['nombre'],
      program['program'],
      profileData['program'],
      profileData['programa'],
      apprentice['programa'],
      apprentice['program'],
      dashboardData['programa'],
    ]),
    'ficha': _firstString([
      ficha['numero_ficha'],
      ficha['numeroFicha'],
      ficha['ficha'],
      ficha['codigo'],
      _firstListValue(roleInfo['fichas_activas']),
      _firstListValue(roleInfo['fichasActivas']),
      profileData['ficha'],
      apprentice['ficha'],
      apprentice['numero_ficha'],
      apprentice['numeroFicha'],
    ]),
    'stage': _firstString([
      apprentice['etapa'],
      apprentice['etapa_actual'],
      apprentice['etapaActual'],
      ficha['etapa'],
      ficha['etapa_actual'],
      profileData['stage'],
      profileData['etapa'],
      'Lectiva',
    ]),
    'schedule': _firstString([
      profileData['schedule'],
      profileData['horario'],
      sessionSchedule,
      activeSession['horario'],
      ficha['jornada'],
    ]),
    'status_label': _statusLabel(
      _firstString([
        apprentice['estado'],
        apprentice['estado_aprendiz'],
        apprentice['estadoAprendiz'],
        user['estado'],
        user['activo'],
        sessionUser['estado'],
        sessionUser['activo'],
        profileData['status_label'],
      ]),
    ),
    'photo_url': _firstString([
      profileData['foto_perfil_url'],
      profileData['photo_url'],
      user['foto_perfil_url'],
      user['photo_url'],
      sessionUser['foto_perfil_url'],
      sessionUser['photo_url'],
      authData['foto_perfil_url'],
      userData['foto_perfil_url'],
    ]),
    'emergency_contact': {
      'name': _firstString([
        emergencyContact['name'],
        emergencyContact['nombre'],
        emergencyContact['nombre_completo'],
        profileData['nombre_contacto_emergencia'],
        user['nombre_contacto_emergencia'],
        sessionUser['nombre_contacto_emergencia'],
      ]),
      'relationship': _firstString([
        emergencyContact['relationship'],
        emergencyContact['parentesco'],
        profileData['parentesco_contacto_emergencia'],
        user['parentesco_contacto_emergencia'],
        sessionUser['parentesco_contacto_emergencia'],
      ]),
      'phone': _firstString([
        emergencyContact['phone'],
        emergencyContact['telefono'],
        emergencyContact['celular'],
        profileData['telefono_contacto_emergencia'],
        user['telefono_contacto_emergencia'],
        sessionUser['telefono_contacto_emergencia'],
      ]),
      'email': _firstString([
        emergencyContact['email'],
        emergencyContact['correo'],
        emergencyContact['correo_electronico'],
        profileData['correo_contacto_emergencia'],
        user['correo_contacto_emergencia'],
        sessionUser['correo_contacto_emergencia'],
      ]),
    },
  };
}

Map<String, dynamic> _firstMap(List<Object?> values) {
  for (final value in values) {
    if (value is Map<String, dynamic> && value.isNotEmpty) {
      return value;
    }
  }
  return const {};
}

String _firstString(List<Object?> values) {
  for (final value in values) {
    if (value == null) {
      continue;
    }
    if (value is Map<String, dynamic>) {
      final nested = _firstString([
        value['nombre_completo'],
        value['nombre_programa'],
        value['nombre'],
        value['name'],
        value['label'],
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

String _firstListValue(Object? value) {
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) {
      return _firstString([
        first['numero_ficha'],
        first['numeroFicha'],
        first['ficha'],
        first['nombre'],
        first['name'],
      ]);
    }
    return first.toString().trim();
  }
  return '';
}

String _statusLabel(String value) {
  if (value.isEmpty) {
    return 'Activo';
  }

  final normalized = value.toLowerCase();
  if (normalized == 'true' ||
      normalized == 'activo' ||
      normalized == 'activa') {
    return 'Activo';
  }
  if (normalized == 'false' || normalized == 'inactivo') {
    return 'Inactivo';
  }
  return value;
}

String _shortTime(String value) {
  return value.length >= 5 ? value.substring(0, 5) : value;
}

const _mockProfileResponse = {
  'id': '1234567890',
  'first_name': 'Juan',
  'last_name': 'Perez Garcia',
  'document_type': 'Cedula',
  'document_number': '1.123.456.789',
  'email': 'juan.perez@misena.edu.co',
  'phone': '300 123 4567',
  'program': 'Desarrollo de Software',
  'ficha': '1234567',
  'stage': 'Lectiva',
  'schedule': 'Lun. a Vie. 7:00 a. m.',
  'status_label': 'Activo',
  'emergency_contact': {
    'name': 'Maria Garcia',
    'relationship': 'Madre',
    'phone': '310 456 7890',
    'email': 'maria.garcia@email.com',
  },
};
