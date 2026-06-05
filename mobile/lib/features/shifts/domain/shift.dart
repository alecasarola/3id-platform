enum ShiftStatus { draft, published, filled, cancelled, completed }

class Shift {
  const Shift({
    required this.id,
    required this.facilityId,
    required this.requiredRole,
    required this.startAt,
    required this.endAt,
    this.status = ShiftStatus.draft,
    this.title,
    this.description,
    this.createdAt,
  });

  final String id;
  final String facilityId;
  final String requiredRole;
  final DateTime startAt;
  final DateTime endAt;
  final ShiftStatus status;
  final String? title;
  final String? description;
  final DateTime? createdAt;

  Duration get duration => endAt.difference(startAt);
  bool get isPublished => status == ShiftStatus.published;

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
    id: json['id'] as String,
    facilityId: json['facility_id'] as String,
    requiredRole: json['required_role'] as String,
    startAt: DateTime.parse(json['start_at'] as String).toLocal(),
    endAt: DateTime.parse(json['end_at'] as String).toLocal(),
    status: ShiftStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ShiftStatus.draft,
    ),
    title: json['title'] as String?,
    description: json['description'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String).toLocal()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'facility_id': facilityId,
    'required_role': requiredRole,
    'start_at': startAt.toUtc().toIso8601String(),
    'end_at': endAt.toUtc().toIso8601String(),
    'status': status.name,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
  };

  Shift copyWith({
    String? facilityId,
    String? requiredRole,
    DateTime? startAt,
    DateTime? endAt,
    ShiftStatus? status,
    String? title,
    String? description,
  }) =>
      Shift(
        id: id,
        facilityId: facilityId ?? this.facilityId,
        requiredRole: requiredRole ?? this.requiredRole,
        startAt: startAt ?? this.startAt,
        endAt: endAt ?? this.endAt,
        status: status ?? this.status,
        title: title ?? this.title,
        description: description ?? this.description,
        createdAt: createdAt,
      );
}
