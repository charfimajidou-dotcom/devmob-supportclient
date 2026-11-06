import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ticket.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_screen.dart';

/// Liste des tickets avec recherche et filtres
/// (statut, catégorie, priorité, date, utilisateur).
class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _status;
  String? _category;
  String? _priority;
  int? _clientId;
  DateTimeRange? _range;
  bool _mine = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _activeFilters =>
      [_category, _priority, _clientId, _range].where((e) => e != null).length +
      (_mine ? 1 : 0);

  List<Ticket> _apply(List<Ticket> all, AppUser user) {
    final q = normalize(_query.trim());
    final range = _range;
    return all.where((t) {
      if (_status != null && t.status != _status) return false;
      if (_category != null && t.category != _category) return false;
      if (_priority != null && t.priority != _priority) return false;
      if (_clientId != null && t.clientId != _clientId) return false;
      if (_mine && t.agentId != user.id) return false;
      if (range != null) {
        final d = DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day);
        if (d.isBefore(range.start) || d.isAfter(range.end)) return false;
      }
      if (q.isNotEmpty) {
        final hay = normalize(
            '${t.id} ${t.title} ${t.description} ${t.category} ${t.clientName ?? ''}');
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TicketProvider>();
    final user = context.watch<AuthProvider>().user!;
    final list = _apply(prov.tickets, user);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher (titre, n°, client...)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Filtres',
                onPressed: () => _openFilters(prov, user),
                icon: Badge(
                  isLabelVisible: _activeFilters > 0,
                  label: Text('$_activeFilters'),
                  child: const Icon(Icons.tune),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _chip(null, 'Tous', prov.tickets.length),
              for (final s in TicketStatus.all)
                _chip(s, TicketStatus.label(s),
                    prov.tickets.where((t) => t.status == s).length),
            ],
          ),
        ),
        Expanded(
          child: prov.loading && prov.tickets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: prov.refresh,
                  child: list.isEmpty
                      ? ListView(children: [const SizedBox(height: 80), _empty(user)])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) => TicketCard(
                            ticket: list[i],
                            showClient: user.isStaff,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketDetailScreen(ticketId: list[i].id!),
                              ),
                            ),
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String? value, String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: _status == value,
        onSelected: (_) => setState(() => _status = value),
      ),
    );
  }

  Widget _empty(AppUser user) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _query.isNotEmpty || _status != null || _activeFilters > 0;
    return Column(
      children: [
        Icon(Icons.inbox_outlined, size: 72, color: scheme.outline),
        const SizedBox(height: 12),
        Text(filtered ? 'Aucun ticket ne correspond aux filtres' : 'Aucun ticket',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (!user.isStaff && !filtered)
          const Text('Appuyez sur « Nouveau ticket » pour signaler un problème.'),
      ],
    );
  }

  Future<void> _openFilters(TicketProvider prov, AppUser user) async {
    String? cat = _category;
    String? prio = _priority;
    int? client = _clientId;
    DateTimeRange? range = _range;
    bool mine = _mine;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filtres', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: cat,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Catégorie', prefixIcon: Icon(Icons.category_outlined)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Toutes')),
                    ...kCategories
                        .map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => setSheet(() => cat = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: prio,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Priorité', prefixIcon: Icon(Icons.flag_outlined)),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Toutes')),
                    ...TicketPriority.all.map((p) => DropdownMenuItem<String?>(
                        value: p, child: Text(TicketPriority.label(p)))),
                  ],
                  onChanged: (v) => setSheet(() => prio = v),
                ),
                if (user.isStaff) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: client,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Client', prefixIcon: Icon(Icons.person_outline)),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
                      ...prov.clients.map(
                          (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setSheet(() => client = v),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final r = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: range,
                    );
                    if (r != null) setSheet(() => range = r);
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(range == null
                      ? 'Période : toutes les dates'
                      : '${formatShortDate(range!.start)} → ${formatShortDate(range!.end)}'),
                ),
                if (user.isStaff)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uniquement les tickets qui me sont affectés'),
                    value: mine,
                    onChanged: (v) => setSheet(() => mine = v),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _category = null;
                            _priority = null;
                            _clientId = null;
                            _range = null;
                            _mine = false;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _category = cat;
                            _priority = prio;
                            _clientId = client;
                            _range = range;
                            _mine = mine;
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
