import 'package:flutter/material.dart';

/// Statuts possibles d'un ticket.
class TicketStatus {
  static const nouveau = 'nouveau';
  static const enCours = 'en_cours';
  static const resolu = 'resolu';
  static const ferme = 'ferme';

  static const all = [nouveau, enCours, resolu, ferme];

  static const _labels = {
    nouveau: 'Nouveau',
    enCours: 'En cours',
    resolu: 'Résolu',
    ferme: 'Fermé',
  };

  static const _colors = {
    nouveau: Color(0xFF1E88E5),
    enCours: Color(0xFFFB8C00),
    resolu: Color(0xFF43A047),
    ferme: Color(0xFF757575),
  };

  static const _icons = {
    nouveau: Icons.fiber_new_outlined,
    enCours: Icons.autorenew,
    resolu: Icons.check_circle_outline,
    ferme: Icons.lock_outline,
  };

  static String label(String s) => _labels[s] ?? s;
  static Color color(String s) => _colors[s] ?? Colors.grey;
  static IconData icon(String s) => _icons[s] ?? Icons.help_outline;
}

/// Niveaux de priorité.
class TicketPriority {
  static const basse = 'basse';
  static const moyenne = 'moyenne';
  static const haute = 'haute';
  static const urgente = 'urgente';

  static const all = [basse, moyenne, haute, urgente];

  static const _labels = {
    basse: 'Basse',
    moyenne: 'Moyenne',
    haute: 'Haute',
    urgente: 'Urgente',
  };

  static const _colors = {
    basse: Color(0xFF78909C),
    moyenne: Color(0xFF1E88E5),
    haute: Color(0xFFFB8C00),
    urgente: Color(0xFFE53935),
  };

  static String label(String p) => _labels[p] ?? p;
  static Color color(String p) => _colors[p] ?? Colors.grey;
}

/// Rôles des utilisateurs.
class Roles {
  static const client = 'client';
  static const agent = 'agent';
  static const admin = 'admin';

  static String label(String r) {
    if (r == admin) return 'Administrateur';
    if (r == agent) return 'Agent support';
    return 'Client';
  }
}

/// Catégories de problème proposées à la création d'un ticket.
const kCategories = [
  'Connexion / compte',
  'Matériel',
  'Logiciel',
  'Réseau / Internet',
  'Facturation',
  'Demande administrative',
  'Autre',
];

/// Couleurs utilisées dans les graphiques par catégorie.
const kCategoryColors = [
  Color(0xFF3949AB),
  Color(0xFF00897B),
  Color(0xFFF4511E),
  Color(0xFF8E24AA),
  Color(0xFFFDD835),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
];

Color categoryColor(String category) {
  final i = kCategories.indexOf(category);
  return kCategoryColors[(i < 0 ? kCategories.length - 1 : i) % kCategoryColors.length];
}

// ---------------------------------------------------------------------------
// Fonctions utilitaires (dates, texte)
// ---------------------------------------------------------------------------

String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime d) =>
    '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';

String formatShortDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

String formatDuration(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h ${d.inMinutes % 60} min';
  return '${d.inDays} j ${d.inHours % 24} h';
}

String timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return formatShortDate(d);
}

/// Met en minuscules et enlève les accents (pour la recherche).
String normalize(String s) {
  const from = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}
