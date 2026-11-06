import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/faq_item.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import 'create_ticket_screen.dart';

/// Affiche la réponse d'un article de FAQ dans une boîte de dialogue.
Future<void> showFaqDialog(BuildContext context, FaqItem f) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lightbulb_outline),
      title: Text(f.question),
      content: Text(f.answer),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Merci, compris')),
      ],
    ),
  );
}

/// FAQ interactive + assistant automatique (recherche par mots-clés).
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final prov = context.watch<TicketProvider>();
    final user = context.watch<AuthProvider>().user!;

    final q = normalize(_query.trim());
    List<FaqItem> items;
    if (q.isEmpty) {
      items = prov.faq;
    } else {
      // Articles correspondant aux mots-clés, triés par pertinence,
      // puis ceux qui contiennent simplement le texte recherché.
      final best = prov.suggest(_query, max: 10);
      final others = prov.faq.where((f) =>
          !best.contains(f) && normalize('${f.question} ${f.answer}').contains(q));
      items = [...best, ...others];
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text('Assistant automatique',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Décrivez votre problème : je vous propose les articles les plus utiles.',
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Ex : mot de passe oublié',
                    prefixIcon: const Icon(Icons.search),
                    fillColor: scheme.surface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(q.isEmpty ? 'Questions fréquentes' : 'Résultats (${items.length})',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Aucun article ne correspond à votre recherche.'),
                  if (!user.isStaff) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Créer un ticket'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        for (final f in items)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              leading: const Icon(Icons.help_outline),
              title: Text(f.question, style: const TextStyle(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedAlignment: Alignment.centerLeft,
              children: [Text(f.answer)],
            ),
          ),
      ],
    );
  }
}
