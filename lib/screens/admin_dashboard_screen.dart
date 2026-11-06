import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/stat_widget.dart';

/// Historique et reporting : nombre de tickets par statut, temps moyen
/// de résolution, graphique par type de problème, charge par agent.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TicketProvider>();
    final scheme = Theme.of(context).colorScheme;
    final tickets = prov.tickets;
    final byStatus = prov.countBy((t) => t.status);
    final byCategory = prov.countBy((t) => t.category);
    final byPriority = prov.countBy((t) => t.priority);
    final avg = prov.averageResolution;

    return RefreshIndicator(
      onRefresh: prov.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatWidget(
                title: 'Total tickets',
                value: '${tickets.length}',
                icon: Icons.confirmation_number_outlined,
                color: scheme.primary,
              ),
              StatWidget(
                title: 'Temps moyen résolution',
                value: avg == null ? '—' : formatDuration(avg),
                icon: Icons.timer_outlined,
                color: Colors.purple,
              ),
              for (final s in TicketStatus.all)
                StatWidget(
                  title: TicketStatus.label(s),
                  value: '${byStatus[s] ?? 0}',
                  icon: TicketStatus.icon(s),
                  color: TicketStatus.color(s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Tickets par type de problème',
            child: byCategory.isEmpty
                ? const Text('Aucune donnée')
                : Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              for (final e in byCategory.entries)
                                PieChartSectionData(
                                  value: e.value.toDouble(),
                                  color: categoryColor(e.key),
                                  title: '${e.value}',
                                  radius: 60,
                                  titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          for (final e in byCategory.entries)
                            _Legend(color: categoryColor(e.key), label: '${e.key} (${e.value})'),
                        ],
                      ),
                    ],
                  ),
          ),
          _Section(
            title: 'Tickets par priorité',
            child: SizedBox(height: 200, child: _priorityChart(context, byPriority)),
          ),
          _Section(
            title: 'Charge par membre du support',
            child: Column(
              children: [
                for (final s in prov.staff)
                  Builder(builder: (context) {
                    final assigned = tickets.where((t) => t.agentId == s.id).toList();
                    final open = assigned
                        .where((t) =>
                            t.status == TicketStatus.nouveau || t.status == TicketStatus.enCours)
                        .length;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(child: Text(s.name[0].toUpperCase())),
                      title: Text(s.name),
                      subtitle: Text(Roles.label(s.role)),
                      trailing: Text('${assigned.length} affectés\n$open ouverts',
                          textAlign: TextAlign.end),
                    );
                  }),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.help_outline)),
                  title: const Text('Non affectés'),
                  trailing: Text('${tickets.where((t) => t.agentId == null).length}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityChart(BuildContext context, Map<String, int> byPriority) {
    final values = [for (final p in TicketPriority.all) (byPriority[p] ?? 0).toDouble()];
    final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue < 4 ? 4.0 : maxValue + 1;
    final style = Theme.of(context).textTheme.bodySmall;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: style),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= TicketPriority.all.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(TicketPriority.label(TicketPriority.all[i]), style: style),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: TicketPriority.color(TicketPriority.all[i]),
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
