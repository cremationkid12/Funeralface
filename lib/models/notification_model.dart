class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? entityType;
  final String? entityId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  static NotificationModel? fromPushData(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (type.isEmpty) return null;
    return NotificationModel(
      id: data['notification_id']?.toString() ?? '',
      type: type,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      entityType: data['entity_type']?.toString(),
      entityId: data['entity_id']?.toString(),
      readAt: null,
      createdAt: DateTime.now(),
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      entityType: json['entity_type']?.toString(),
      entityId: json['entity_id']?.toString(),
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
