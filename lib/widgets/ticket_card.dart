import 'package:flutter/material.dart';

import '../models/ticket.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

/// Carte résumant un ticket dans la liste.
class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool showClient;
  final VoidCallback? onTap;

  const TicketCard({super.key, required this.ticket, this.showClient = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = ticket;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: TicketStatus.color(t.status), width: 5)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${t.id}',
                      style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.category, style: small, overflow: TextOverflow.ellipsis),
                  ),
                  StatusBadge(status: t.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                t.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  PriorityBadge(priority: t.priority),
                  const Spacer(),
                  if (t.attachmentCount > 0) ...[
                    Icon(Icons.attach_file, size: 16, color: scheme.outline),
                    Text('${t.attachmentCount}', style: small),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.chat_bubble_outline, size: 16, color: scheme.outline),
                  const SizedBox(width: 4),
                  Text('${t.commentCount}', style: small),
                  const SizedBox(width: 10),
                  Text(timeAgo(t.updatedAt), style: small),
                ],
              ),
              if (showClient) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: scheme.outline),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${t.clientName ?? '-'}  •  '
                        '${t.agentName != null ? 'Agent : ${t.agentName}' : 'Non affecté'}',
                        style: small,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
