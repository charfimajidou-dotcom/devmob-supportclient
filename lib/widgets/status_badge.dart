import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Badge coloré affichant le statut d'un ticket.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = TicketStatus.color(status);
    return _Pill(color: c, icon: TicketStatus.icon(status), label: TicketStatus.label(status));
  }
}

/// Badge coloré affichant la priorité d'un ticket.
class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = TicketPriority.color(priority);
    return _Pill(color: c, icon: Icons.flag_outlined, label: TicketPriority.label(priority));
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _Pill({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
