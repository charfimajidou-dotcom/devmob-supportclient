import '../utils/constants.dart';

/// Article de la FAQ, avec des mots-clés pour l'assistant automatique.
class FaqItem {
  final int id;
  final String question;
  final String answer;
  final List<String> keywords;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.keywords,
  });

  /// Nombre de mots-clés trouvés dans le texte (0 = pas pertinent).
  int score(String text) {
    final t = normalize(text);
    return keywords.where((k) => k.isNotEmpty && t.contains(k)).length;
  }

  factory FaqItem.fromMap(Map<String, Object?> m) => FaqItem(
        id: m['id'] as int,
        question: m['question'] as String,
        answer: m['answer'] as String,
        keywords: (m['keywords'] as String)
            .split(',')
            .map((k) => normalize(k.trim()))
            .toList(),
      );
}
