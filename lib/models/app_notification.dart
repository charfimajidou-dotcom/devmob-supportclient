/// Notification interne (nouvelle réponse, changement de statut, affectation...).
class AppNotification {
  final int id;
  final int userId;
  final int? ticketId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.ticketId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
        id: m['id'] as int,
        userId: m['user_id'] as int,
        ticketId: m['ticket_id'] as int?,
        message: m['message'] as String,
        isRead: (m['is_read'] as int) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
