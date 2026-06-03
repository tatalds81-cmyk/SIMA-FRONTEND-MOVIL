import 'package:sima_movil_froned/features/profile/models/apprentice_profile.dart';

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
