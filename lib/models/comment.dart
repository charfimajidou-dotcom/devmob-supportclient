/// Message du fil de discussion d'un ticket.
class TicketComment {
  final int id;
  final int ticketId;
  final int userId;
  final String message;
  final DateTime createdAt;
  final String userName;
  final String userRole;

  const TicketComment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.userName,
    required this.userRole,
  });

  bool get fromStaff => userRole != 'client';

  factory TicketComment.fromMap(Map<String, Object?> m) => TicketComment(
        id: m['id'] as int,
        ticketId: m['ticket_id'] as int,
        userId: m['user_id'] as int,
        message: m['message'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        userName: (m['user_name'] as String?) ?? 'Utilisateur',
        userRole: (m['user_role'] as String?) ?? 'client',
      );
}
