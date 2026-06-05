class NurseProfile {
  const NurseProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.taxCode,
    this.phone,
    this.city,
    this.province,
    this.postalCode,
    this.qualificationType,
    this.licenseNumber,
    this.licenseProvince,
    this.specializations = const [],
  });

  final String id;

  // Anagrafica
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? taxCode;
  final String? phone;
  final String? city;
  final String? province;
  final String? postalCode;

  // Abilitazione professionale
  final String? qualificationType;
  final String? licenseNumber;
  final String? licenseProvince;
  final List<String> specializations;

  String get displayName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  bool get isProfileComplete =>
      firstName != null &&
      lastName != null &&
      qualificationType != null &&
      licenseNumber != null;

  factory NurseProfile.fromJson(Map<String, dynamic> json) => NurseProfile(
    id: json['id'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    dateOfBirth: json['date_of_birth'] != null
        ? DateTime.parse(json['date_of_birth'] as String)
        : null,
    taxCode: json['tax_code'] as String?,
    phone: json['phone'] as String?,
    city: json['city'] as String?,
    province: json['province'] as String?,
    postalCode: json['postal_code'] as String?,
    qualificationType: json['qualification_type'] as String?,
    licenseNumber: json['license_number'] as String?,
    licenseProvince: json['license_province'] as String?,
    specializations:
        (json['specializations'] as List<dynamic>?)?.cast<String>() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    if (dateOfBirth != null)
      'date_of_birth': dateOfBirth!.toIso8601String().substring(0, 10),
    'tax_code': taxCode,
    'phone': phone,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'qualification_type': qualificationType,
    'license_number': licenseNumber,
    'license_province': licenseProvince,
    'specializations': specializations,
  };

  NurseProfile copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? taxCode,
    String? phone,
    String? city,
    String? province,
    String? postalCode,
    String? qualificationType,
    String? licenseNumber,
    String? licenseProvince,
    List<String>? specializations,
  }) =>
      NurseProfile(
        id: id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        taxCode: taxCode ?? this.taxCode,
        phone: phone ?? this.phone,
        city: city ?? this.city,
        province: province ?? this.province,
        postalCode: postalCode ?? this.postalCode,
        qualificationType: qualificationType ?? this.qualificationType,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        licenseProvince: licenseProvince ?? this.licenseProvince,
        specializations: specializations ?? this.specializations,
      );
}
