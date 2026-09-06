class ReviewTask {
  final String id;
  final String entityType;
  final String entityId;
  final String reason;
  final String status;
  final int priority;
  final String? notes;
  final DateTime createdAt;

  const ReviewTask({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.reason,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.notes,
  });

  factory ReviewTask.fromMap(Map<String, dynamic> m) => ReviewTask(
    id: m['id'] as String,
    entityType: m['entity_type'] as String,
    entityId: m['entity_id'] as String,
    reason: m['reason'] as String,
    status: m['status'] as String? ?? 'open',
    priority: m['priority'] as int? ?? 3,
    notes: m['notes'] as String?,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class ContentReport {
  final String id;
  final String entityType;
  final String entityId;
  final String reason;
  final String? details;
  final String status;
  final DateTime createdAt;

  const ContentReport({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.details,
  });

  factory ContentReport.fromMap(Map<String, dynamic> m) => ContentReport(
    id: m['id'] as String,
    entityType: m['entity_type'] as String,
    entityId: m['entity_id'] as String,
    reason: m['reason'] as String,
    details: m['details'] as String?,
    status: m['status'] as String? ?? 'open',
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class AuditLogEntry {
  final String id;
  final String? actorId;
  final String? actorRole;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.metadata,
    required this.createdAt,
    this.actorId,
    this.actorRole,
    this.entityType,
    this.entityId,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> m) => AuditLogEntry(
    id: m['id'] as String,
    actorId: m['actor_id'] as String?,
    actorRole: m['actor_role'] as String?,
    action: m['action'] as String,
    entityType: m['entity_type'] as String?,
    entityId: m['entity_id'] as String?,
    metadata: (m['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class ContentVersionSnapshot {
  final String id;
  final String entityType;
  final String entityId;
  final int versionNumber;
  final Map<String, dynamic> snapshot;
  final String contentStatus;
  final String? changeSummary;
  final DateTime createdAt;

  const ContentVersionSnapshot({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.versionNumber,
    required this.snapshot,
    required this.contentStatus,
    required this.createdAt,
    this.changeSummary,
  });

  factory ContentVersionSnapshot.fromMap(Map<String, dynamic> m) =>
      ContentVersionSnapshot(
        id: m['id'] as String,
        entityType: m['entity_type'] as String,
        entityId: m['entity_id'] as String,
        versionNumber: m['version_number'] as int,
        snapshot: (m['snapshot'] as Map).cast<String, dynamic>(),
        contentStatus: m['content_status'] as String,
        changeSummary: m['change_summary'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class AdminProfile {
  final String id;
  final String nickname;
  final String role;
  final DateTime createdAt;

  const AdminProfile({
    required this.id,
    required this.nickname,
    required this.role,
    required this.createdAt,
  });

  factory AdminProfile.fromMap(Map<String, dynamic> m) => AdminProfile(
    id: m['id'] as String,
    nickname: m['nickname'] as String,
    role: m['role'] as String? ?? 'learner',
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  static const assignableRoles = [
    'learner',
    'educator',
    'content_reviewer',
    'admin',
    'super_admin',
  ];
}
