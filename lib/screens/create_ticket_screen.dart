import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/faq_item.dart';
import '../models/ticket.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import 'faq_screen.dart';

/// Formulaire de création d'un ticket (titre, description, catégorie,
/// priorité, pièces jointes) + suggestions automatiques de la FAQ.
class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _picker = ImagePicker();
  final List<AttachmentData> _images = [];
  String _category = kCategories.first;
  String _priority = TicketPriority.moyenne;
  List<FaqItem> _suggestions = [];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  /// Assistant automatique : propose des articles de FAQ selon le texte saisi.
  void _updateSuggestions() {
    final text = '${_title.text} ${_desc.text}';
    setState(() {
      _suggestions =
          text.trim().length < 4 ? [] : context.read<TicketProvider>().suggest(text);
    });
  }

  Future<void> _pickGallery() async {
    try {
      final files = await _picker.pickMultiImage(maxWidth: 1280, imageQuality: 75);
      for (final f in files) {
        await _addFile(f);
      }
    } catch (e) {
      _showError("Impossible d'ouvrir la galerie : $e");
    }
  }

  Future<void> _pickCamera() async {
    try {
      final file = await _picker.pickImage(
          source: ImageSource.camera, maxWidth: 1280, imageQuality: 75);
      if (file != null) await _addFile(file);
    } catch (e) {
      _showError("Impossible d'ouvrir la caméra : $e");
    }
  }

  /// Lit l'image (marche sur Android et sur Chrome).
  Future<void> _addFile(XFile f) async {
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    setState(() => _images.add(AttachmentData(name: f.name, bytes: bytes)));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prov = context.read<TicketProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await prov.createTicket(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        priority: _priority,
        category: _category,
        images: List.of(_images),
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('✅ Ticket envoyé ! Le support a été notifié.')),
      );
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showError('Erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau ticket')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _updateSuggestions(),
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex : Impossible de me connecter',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 5) ? 'Au moins 5 caractères' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _updateSuggestions(),
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Décrivez le problème en détail...',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? 'Au moins 10 caractères' : null,
            ),
            if (_suggestions.isNotEmpty) _suggestionsCard(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Catégorie du problème',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 20),
            Text('Priorité', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: TicketPriority.all
                  .map((p) => ButtonSegment<String>(
                        value: p,
                        label: Text(TicketPriority.label(p),
                            style: TextStyle(color: TicketPriority.color(p))),
                      ))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Pièces jointes (${_images.length})',
                      style: theme.textTheme.titleSmall),
                ),
                TextButton.icon(
                  onPressed: _pickGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
                TextButton.icon(
                  onPressed: _pickCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Caméra'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_images.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Ajoutez des captures d'écran pour aider le support (facultatif).",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_images[i].bytes,
                            width: 96, height: 96, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Envoyer le ticket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionsCard() {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.amber.withAlpha(45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Assistant : ces articles peuvent résoudre votre problème',
                      style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            for (final f in _suggestions)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: Text(f.question),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showFaqDialog(context, f),
              ),
          ],
        ),
      ),
    );
  }
}
