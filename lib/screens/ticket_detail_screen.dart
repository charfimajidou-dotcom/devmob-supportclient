import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comment.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/comment_bubble.dart';
import '../widgets/status_badge.dart';

/// Détail d'un ticket : infos, pièces jointes, gestion (support) et discussion.
class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _msg = TextEditingController();
  final _scroll = ScrollController();
  List<TicketComment> _comments = [];
  List<Attachment> _attachments = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _msg.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadThread({bool scrollToEnd = false}) async {
    final prov = context.read<TicketProvider>();
    final c = await prov.comments(widget.ticketId);
    final a = await prov.attachments(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _comments = c;
      _attachments = a;
    });
    if (scrollToEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String message) async {
    final messenger = ScaffoldMessenger.of(context);
    await action();
    await _loadThread(scrollToEnd: true);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send(Ticket t) async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await context.read<TicketProvider>().addComment(t, text);
    if (!mounted) return;
    _msg.clear();
    await _loadThread(scrollToEnd: true);
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TicketProvider>();
    final user = context.watch<AuthProvider>().user!;
    final t = prov.byId(widget.ticketId);

    if (t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ticket introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ticket #${t.id}')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await prov.refresh();
                await _loadThread();
              },
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  _header(t),
                  if (_attachments.isNotEmpty) _attachmentsView(),
                  if (user.isStaff) _staffPanel(t, prov),
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.forum_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('Discussion (${_comments.length})',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Aucun message pour le moment.'),
                    ),
                  for (final c in _comments)
                    CommentBubble(comment: c, isMine: c.userId == user.id),
                ],
              ),
            ),
          ),
          _inputBar(t, user),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ en-tête

  Widget _header(Ticket t) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [StatusBadge(status: t.status), PriorityBadge(priority: t.priority)],
            ),
            const SizedBox(height: 12),
            Text(t.title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(t.description, style: theme.textTheme.bodyLarge),
            const Divider(height: 28),
            _info(Icons.category_outlined, 'Catégorie', t.category),
            _info(Icons.person_outline, 'Client', t.clientName ?? '-'),
            _info(Icons.support_agent, 'Agent', t.agentName ?? 'Non affecté'),
            _info(Icons.schedule, 'Créé le', formatDate(t.createdAt)),
            _info(Icons.update, 'Mis à jour', formatDate(t.updatedAt)),
            if (t.resolvedAt != null)
              _info(Icons.task_alt, 'Résolu le',
                  '${formatDate(t.resolvedAt!)} (en ${formatDuration(t.resolutionTime!)})'),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: Text(label, style: theme.textTheme.bodySmall)),
          Expanded(
            child: Text(value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- pièces jointes

  Widget _attachmentsView() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pièces jointes (${_attachments.length})',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final bytes = _attachments[i].data;
                return GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      clipBehavior: Clip.antiAlias,
                      child: InteractiveViewer(child: Image.memory(bytes)),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      bytes,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.withAlpha(60),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- panneau support/admin

  Widget _staffPanel(Ticket t, TicketProvider prov) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: theme.colorScheme.secondaryContainer.withAlpha(110),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined),
                const SizedBox(width: 8),
                Text('Gestion du ticket', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('status-${t.status}'),
              value: t.status,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Statut', prefixIcon: Icon(Icons.timelapse)),
              items: TicketStatus.all
                  .map((s) => DropdownMenuItem(value: s, child: Text(TicketStatus.label(s))))
                  .toList(),
              onChanged: (v) {
                if (v != null && v != t.status) {
                  _run(() => prov.changeStatus(t, v), 'Statut mis à jour');
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('prio-${t.priority}'),
              value: t.priority,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Priorité', prefixIcon: Icon(Icons.flag_outlined)),
              items: TicketPriority.all
                  .map((p) => DropdownMenuItem(value: p, child: Text(TicketPriority.label(p))))
                  .toList(),
              onChanged: (v) {
                if (v != null && v != t.priority) {
                  _run(() => prov.changePriority(t, v), 'Priorité mise à jour');
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey('agent-${t.agentId}'),
              value: t.agentId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Affecté à', prefixIcon: Icon(Icons.support_agent)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Non affecté')),
                ...prov.staff.map((s) => DropdownMenuItem<int?>(
                    value: s.id, child: Text('${s.name} (${Roles.label(s.role)})'))),
              ],
              onChanged: (v) {
                if (v != t.agentId) _run(() => prov.assign(t, v), 'Affectation mise à jour');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ saisie message

  Widget _inputBar(Ticket t, AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    if (t.status == TicketStatus.ferme && !user.isStaff) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: scheme.surfaceContainerHighest,
          child: const Text(
            '🔒 Ce ticket est fermé. Créez un nouveau ticket si le problème revient.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Material(
      elevation: 6,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msg,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Écrire un message...'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(t),
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
