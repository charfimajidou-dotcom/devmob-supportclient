import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import 'ticket_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TicketProvider>();
    final list = prov.notifications;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (prov.unreadCount > 0)
            TextButton(onPressed: prov.markAllRead, child: const Text('Tout lire')),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: scheme.outline),
                  const SizedBox(height: 12),
                  const Text('Aucune notification'),
                ],
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final n = list[i];
                return ListTile(
                  tileColor: n.isRead ? null : scheme.primaryContainer.withAlpha(70),
                  leading: CircleAvatar(
                    child: Icon(n.isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active),
                  ),
                  title: Text(
                    n.message,
                    style: TextStyle(
                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600),
                  ),
                  subtitle: Text(timeAgo(n.createdAt)),
                  onTap: () async {
                    await prov.markRead(n);
                    if (!ctx.mounted || n.ticketId == null) return;
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticketId: n.ticketId!)),
                    );
                  },
                );
              },
            ),
    );
  }
}
