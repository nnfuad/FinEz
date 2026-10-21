class AuditLog {
  final String id;
  final String? actorId;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? reason;
  final DateTime? createdAt;

  AuditLog({
    required this.id,
    this.actorId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.oldValues,
    this.newValues,
    this.reason,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
      reason: json['reason'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
