class FamilyAssignmentModel {
  const FamilyAssignmentModel({
    required this.assignmentId,
    required this.decedentName,
    required this.status,
    this.etaNote,
    required this.supportContactPhone,
  });

  final String assignmentId;
  final String decedentName;
  final String status;
  final String? etaNote;
  final String supportContactPhone;

  factory FamilyAssignmentModel.fromJson(Map<String, dynamic> json) {
    return FamilyAssignmentModel(
      assignmentId: json['assignment_id']?.toString() ?? '',
      decedentName: json['decedent_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      etaNote: json['eta_note']?.toString(),
      supportContactPhone: json['support_contact_phone']?.toString() ?? '',
    );
  }
}
