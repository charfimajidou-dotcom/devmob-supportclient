import 'dart:typed_data';

/// Un ticket = une demande ou un incident signalé par un client.
class Ticket {
  final int? id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String status;
  final int clientId;
  final int? agentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  // Champs calculés (jointures SQL)
  final String? clientName;
  final String? agentName;
  final int commentCount;
  final int attachmentCount;

  const Ticket({
    this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.status,
    required this.clientId,
    this.agentId,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.clientName,
    this.agentName,
    this.commentCount = 0,
    this.attachmentCount = 0,
  });

  /// Durée entre la création et la résolution.
  Duration? get resolutionTime => resolvedAt?.difference(createdAt);

  Map<String, Object?> toMap() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'status': status,
        'client_id': clientId,
        'agent_id': agentId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  factory Ticket.fromMap(Map<String, Object?> m) => Ticket(
        id: m['id'] as int,
        title: m['title'] as String,
        description: m['description'] as String,
        priority: m['priority'] as String,
        category: m['category'] as String,
        status: m['status'] as String,
        clientId: m['client_id'] as int,
        agentId: m['agent_id'] as int?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        resolvedAt: m['resolved_at'] == null ? null : DateTime.parse(m['resolved_at'] as String),
        clientName: m['client_name'] as String?,
        agentName: m['agent_name'] as String?,
        commentCount: (m['comment_count'] as int?) ?? 0,
        attachmentCount: (m['attachment_count'] as int?) ?? 0,
      );
}

/// Pièce jointe (image / capture d'écran) enregistrée dans SQLite (BLOB).
/// Ce format marche à la fois sur Android et sur Chrome.
class Attachment {
  final int id;
  final int ticketId;
  final String name;
  final Uint8List data;

  const Attachment({
    required this.id,
    required this.ticketId,
    required this.name,
    required this.data,
  });

  factory Attachment.fromMap(Map<String, Object?> m) {
    final raw = m['data'];
    return Attachment(
      id: m['id'] as int,
      ticketId: m['ticket_id'] as int,
      name: m['name'] as String,
      data: raw is Uint8List ? raw : Uint8List.fromList((raw as List).cast<int>()),
    );
  }
}

/// Image choisie dans le formulaire, avant l'enregistrement du ticket.
class AttachmentData {
  final String name;
  final Uint8List bytes;

  const AttachmentData({required this.name, required this.bytes});
}
