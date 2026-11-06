import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../models/comment.dart';
import '../models/faq_item.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../services/db_service.dart';
import '../utils/constants.dart';

/// Gère les tickets, la discussion, les notifications, la FAQ et les stats.
class TicketProvider extends ChangeNotifier {
  final _db = DbService.instance;

  AppUser? _user;
  List<Ticket> tickets = [];
  List<AppUser> users = [];
  List<AppNotification> notifications = [];
  List<FaqItem> faq = [];
  bool loading = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  List<AppUser> get staff => users.where((u) => u.isStaff).toList();
  List<AppUser> get clients => users.where((u) => !u.isStaff).toList();

  /// Chargement initial après la connexion.
  Future<void> load(AppUser user) async {
    _user = user;
    loading = true;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    final u = _user;
    if (u == null) return;
    tickets = await _db.getTickets(clientId: u.isStaff ? null : u.id);
    users = await _db.getUsers();
    notifications = await _db.getNotifications(u.id);
    if (faq.isEmpty) faq = await _db.getFaq();
    loading = false;
    notifyListeners();
  }

  /// Vide les données à la déconnexion.
  void clear() {
    _user = null;
    tickets = [];
    users = [];
    notifications = [];
    notifyListeners();
  }

  Ticket? byId(int id) {
    for (final t in tickets) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---------------------------------------------------------------- tickets

  Future<void> createTicket({
    required String title,
    required String description,
    required String priority,
    required String category,
    required List<AttachmentData> images,
  }) async {
    final u = _user!;
    final now = DateTime.now();
    final id = await _db.insertTicket(
      Ticket(
        title: title,
        description: description,
        priority: priority,
        category: category,
        status: TicketStatus.nouveau,
        clientId: u.id,
        createdAt: now,
        updatedAt: now,
      ),
      images,
    );
    await _notify(staff.map((s) => s.id), id, 'Nouveau ticket #$id : $title');
    await refresh();
  }

  /// Changement de statut (réservé au support).
  Future<void> changeStatus(Ticket t, String status) async {
    final values = <String, Object?>{'status': status};
    if (status == TicketStatus.resolu || status == TicketStatus.ferme) {
      if (t.resolvedAt == null) values['resolved_at'] = DateTime.now().toIso8601String();
    } else {
      values['resolved_at'] = null;
    }
    await _db.updateTicket(t.id!, values);
    await _db.addComment(t.id!, _user!.id,
        '🔄 Statut modifié : ${TicketStatus.label(t.status)} → ${TicketStatus.label(status)}');
    await _notify([t.clientId], t.id!,
        'Ticket #${t.id} : statut « ${TicketStatus.label(status)} »');
    await refresh();
  }

  Future<void> changePriority(Ticket t, String priority) async {
    await _db.updateTicket(t.id!, {'priority': priority});
    await _db.addComment(t.id!, _user!.id,
        '⚑ Priorité modifiée : ${TicketPriority.label(t.priority)} → ${TicketPriority.label(priority)}');
    await refresh();
  }

  /// Affecte le ticket à un membre de l'équipe (ou le désaffecte).
  Future<void> assign(Ticket t, int? agentId) async {
    final values = <String, Object?>{'agent_id': agentId};
    if (agentId != null && t.status == TicketStatus.nouveau) {
      values['status'] = TicketStatus.enCours;
    }
    await _db.updateTicket(t.id!, values);
    String agentName = 'personne';
    for (final s in staff) {
      if (s.id == agentId) agentName = s.name;
    }
    await _db.addComment(t.id!, _user!.id, '👤 Ticket affecté à $agentName');
    if (agentId != null) {
      await _notify([agentId], t.id!, 'Le ticket #${t.id} vous a été affecté');
      await _notify([t.clientId], t.id!, 'Votre ticket #${t.id} est pris en charge');
    }
    await refresh();
  }

  // ------------------------------------------------------------- discussion

  Future<List<TicketComment>> comments(int ticketId) => _db.getComments(ticketId);
  Future<List<Attachment>> attachments(int ticketId) => _db.getAttachments(ticketId);

  Future<void> addComment(Ticket t, String message) async {
    final u = _user!;
    await _db.addComment(t.id!, u.id, message);
    final Iterable<int> targets;
    if (u.isStaff) {
      targets = [t.clientId];
    } else if (t.agentId != null) {
      targets = [t.agentId!];
    } else {
      targets = staff.map((s) => s.id);
    }
    await _notify(targets, t.id!, '${u.name} a répondu au ticket #${t.id}');
    await refresh();
  }

  // ---------------------------------------------------------- notifications

  Future<void> _notify(Iterable<int> userIds, int ticketId, String message) async {
    for (final id in userIds.toSet()) {
      if (id == _user?.id) continue; // on ne se notifie pas soi-même
      await _db.addNotification(id, ticketId, message);
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    await _db.markNotificationRead(n.id);
    await refresh();
  }

  Future<void> markAllRead() async {
    final u = _user;
    if (u == null) return;
    await _db.markAllNotificationsRead(u.id);
    await refresh();
  }

  // ------------------------------------------------------- FAQ / assistant

  /// Articles de FAQ les plus pertinents pour un texte (assistant automatique).
  List<FaqItem> suggest(String text, {int max = 3}) {
    final scored = faq
        .map((f) => MapEntry(f, f.score(text)))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored.take(max).map((e) => e.key).toList();
  }

  // ----------------------------------------------------------- statistiques

  Map<String, int> countBy(String Function(Ticket) key) {
    final map = <String, int>{};
    for (final t in tickets) {
      map[key(t)] = (map[key(t)] ?? 0) + 1;
    }
    return map;
  }

  Duration? get averageResolution {
    final done = tickets.where((t) => t.resolvedAt != null).toList();
    if (done.isEmpty) return null;
    final total = done.fold<int>(0, (sum, t) => sum + t.resolutionTime!.inMinutes);
    return Duration(minutes: total ~/ done.length);
  }
}
