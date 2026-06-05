enum ApplicationStatus { pending, accepted, rejected, withdrawn }

class Application {
  const Application({
    required this.id,
    required this.shiftId,
    required this.nurseId,
    this.status = ApplicationStatus.pending,
    this.note,
    this.appliedAt,
    this.updatedAt,
  });

  final String id;
  final String shiftId;
  final String nurseId;
  final ApplicationStatus status;
  final String? note;
  final DateTime? appliedAt;
  final DateTime? updatedAt;

  bool get isPending   => status == ApplicationStatus.pending;
  bool get isAccepted  => status == ApplicationStatus.accepted;
  bool get isRejected  => status == ApplicationStatus.rejected;
  bool get isWithdrawn => status == ApplicationStatus.withdrawn;

  factory Application.fromJson(Map<String, dynamic> json) => Application(
    id: json['id'] as String,
    shiftId: json['shift_id'] as String,
    nurseId: json['nurse_id'] as String,
    status: ApplicationStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ApplicationStatus.pending,
    ),
    note: json['note'] as String?,
    appliedAt: json['applied_at'] != null
        ? DateTime.parse(json['applied_at'] as String).toLocal()
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String).toLocal()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'shift_id': shiftId,
    'nurse_id': nurseId,
    'status': status.name,
    if (note != null) 'note': note,
  };
}
