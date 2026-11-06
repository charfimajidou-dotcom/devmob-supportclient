import 'package:flutter_test/flutter_test.dart';

import 'package:devmob_supportclient/models/faq_item.dart';
import 'package:devmob_supportclient/utils/constants.dart';

void main() {
  test('normalize enlève les accents et met en minuscules', () {
    expect(normalize('Réseau Été'), 'reseau ete');
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(minutes: 45)), '45 min');
    expect(formatDuration(const Duration(hours: 26)), '1 j 2 h');
  });

  test("l'assistant trouve l'article « mot de passe »", () {
    const faq = FaqItem(
      id: 1,
      question: "J'ai oublié mon mot de passe",
      answer: '...',
      keywords: ['mot de passe', 'oublie'],
    );
    expect(faq.score("J'ai OUBLIÉ mon mot de passe"), 2);
    expect(faq.score('Imprimante en panne'), 0);
  });
}
