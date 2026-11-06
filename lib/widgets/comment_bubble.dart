import 'package:flutter/material.dart';

import '../models/comment.dart';
import '../utils/constants.dart';

/// Bulle de message dans le fil de discussion d'un ticket.
class CommentBubble extends StatelessWidget {
  final TicketComment comment;
  final bool isMine;

  const CommentBubble({super.key, required this.comment, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = isMine
        ? scheme.primaryContainer
        : (comment.fromStaff ? scheme.secondaryContainer : scheme.tertiaryContainer);
    const r = Radius.circular(16);
    const tail = Radius.circular(4);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: isMine ? r : tail,
              bottomRight: isMine ? tail : r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(comment.fromStaff ? Icons.support_agent : Icons.person, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isMine ? 'Vous' : comment.userName,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (comment.fromStaff)
                    Text(' • Support', style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(comment.message),
              const SizedBox(height: 4),
              Text(formatDate(comment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}
