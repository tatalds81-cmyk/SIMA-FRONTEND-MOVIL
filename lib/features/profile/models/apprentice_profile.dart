class ApprenticeProfile {
  const ApprenticeProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.documentType,
    required this.documentNumber,
    required this.email,
    required this.phone,
    required this.program,
    required this.ficha,
    required this.stage,
    required this.schedule,
    required this.statusLabel,
    required this.photoUrl,
    required this.emergencyContact,
  });

  factory ApprenticeProfile.fromJson(Map<String, dynamic> json) {
    final emergencyContactJson =
        json['emergency_contact'] as Map<String, dynamic>? ?? {};

    return ApprenticeProfile(
      id: (json['id'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      documentType: (json['document_type'] ?? '').toString(),
      documentNumber: (json['document_number'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      program: (json['program'] ?? '').toString(),
      ficha: (json['ficha'] ?? '').toString(),
      stage: (json['stage'] ?? '').toString(),
      schedule: (json['schedule'] ?? '').toString(),
      statusLabel: (json['status_label'] ?? 'Activo').toString(),
      photoUrl: (json['photo_url'] ?? json['foto_perfil_url'] ?? '').toString(),
      emergencyContact: EmergencyContact.fromJson(emergencyContactJson),
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String documentType;
  final String documentNumber;
  final String email;
  final String phone;
  final String program;
  final String ficha;
  final String stage;
  final String schedule;
  final String statusLabel;
  final String photoUrl;
  final EmergencyContact emergencyContact;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'AP';
    }

    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  ApprenticeProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? documentType,
    String? documentNumber,
    String? email,
    String? phone,
    String? program,
    String? ficha,
    String? stage,
    String? schedule,
    String? statusLabel,
    String? photoUrl,
    EmergencyContact? emergencyContact,
  }) {
    return ApprenticeProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      program: program ?? this.program,
      ficha: ficha ?? this.ficha,
      stage: stage ?? this.stage,
      schedule: schedule ?? this.schedule,
      statusLabel: statusLabel ?? this.statusLabel,
      photoUrl: photoUrl ?? this.photoUrl,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'document_type': documentType,
      'document_number': documentNumber,
      'email': email,
      'phone': phone,
      'program': program,
      'ficha': ficha,
      'stage': stage,
      'schedule': schedule,
      'status_label': statusLabel,
      'photo_url': photoUrl,
      'emergency_contact': emergencyContact.toJson(),
    };
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.email,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: (json['name'] ?? '').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  final String name;
  final String relationship;
  final String phone;
  final String email;

  EmergencyContact copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
  }) {
    return EmergencyContact(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
    };
  }
}
