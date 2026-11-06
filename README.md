# DEVMOB SupportClient — Projet Flutter 07

Application mobile de **support client / ticketing** : les clients créent des tickets
(incidents ou demandes), suivent leur statut et discutent avec l'équipe support ;
les agents et administrateurs traitent, affectent et résolvent les tickets.

Toutes les données sont stockées **localement dans SQLite** (package `sqflite`) :
l'application fonctionne sans serveur et sans Internet.

---

## 🚀 Lancer le projet

Le zip contient le code (`lib/`, `pubspec.yaml`, `test/`). Les dossiers des plateformes
(`android/`, `ios/`...) sont générés par Flutter sur ton PC :

```bash
# 1. Se placer dans le dossier du projet
cd devmob_supportclient

# 2. Générer les dossiers android/ ios/ ... (ne touche pas à lib/ ni pubspec.yaml)
flutter create --project-name devmob_supportclient --org com.devmob --platforms=android,ios .

# 3. Télécharger les packages
flutter pub get

# 4. Lancer sur l'émulateur Android ou un téléphone branché
flutter run
```

### 🌐 Lancer sur Chrome

```bash
flutter create --platforms=web .
flutter pub get
dart run sqflite_common_ffi_web:setup   # une seule fois : installe SQLite pour le navigateur
flutter run -d chrome
```

Sur Chrome, la base SQLite est enregistrée dans le navigateur (IndexedDB) grâce à
`sqflite_common_ffi_web`. Sur Android, c'est le `sqflite` normal.

### Comptes de démonstration (déjà créés au 1er lancement)

| Rôle | E-mail | Mot de passe |
|------|--------|--------------|
| Client | client@support.tn | client123 |
| Client | amira@support.tn | client123 |
| Agent support | agent@support.tn | agent123 |
| Agent support | leila@support.tn | agent123 |
| Administrateur | admin@support.tn | admin123 |

Sur l'écran de connexion, touche **Client / Agent / Admin** pour remplir automatiquement.
On peut aussi **créer un compte client** avec « Pas de compte ? ».

---

## ✅ Fonctionnalités (cahier des charges)

| Fonctionnalité demandée | Obligatoire | Où dans l'appli |
|---|---|---|
| Authentification e-mail / mot de passe + rôles (Client, Agent, Admin) | ✅ | `login_screen.dart`, `auth_provider.dart` |
| Création de ticket : titre, description, priorité, catégorie | ✅ | `create_ticket_screen.dart` |
| Pièces jointes (images / captures, galerie ou caméra) — `image_picker` | ✅ | `create_ticket_screen.dart` |
| Suivi des statuts : Nouveau, En cours, Résolu, Fermé + badge de couleur | ✅ | `status_badge.dart`, `ticket_card.dart` |
| Changement de statut **côté support uniquement** | ✅ | `ticket_detail_screen.dart` (panneau « Gestion du ticket ») |
| Fil de discussion dans chaque ticket (chat simplifié) | ✅ | `ticket_detail_screen.dart`, `comment_bubble.dart` |
| Notifications à chaque réponse / changement de statut / affectation | ✅ | cloche 🔔 + `notifications_screen.dart` |
| Interface support/admin : affectation, statut, priorité, vue globale | ✅ | `ticket_detail_screen.dart`, `ticket_list_screen.dart` |
| Filtres : catégorie, date, statut, utilisateur + recherche | ✅ | `ticket_list_screen.dart` (icône ⚙ filtres) |
| Statistiques : tickets par statut, temps moyen de résolution, graphique par type — `fl_chart` | ✅ | `admin_dashboard_screen.dart` |
| FAQ interactive + assistant automatique (suggestions selon le texte) | Optionnel ✔ | `faq_screen.dart` + suggestions pendant la création d'un ticket |
| **Bonus** : Dark mode | ✔ | menu profil (avatar en haut à droite) |
| **Bonus** : Badges de notification dynamiques | ✔ | cloche 🔔 |
| **Bonus** : Mode offline (consultation locale) | ✔ | tout est dans SQLite |

### Qui peut faire quoi ?

| Action | Client | Agent | Admin |
|---|:-:|:-:|:-:|
| Créer un ticket | ✅ | | |
| Voir ses tickets | ✅ | | |
| Voir tous les tickets | | ✅ | ✅ |
| Répondre dans la discussion | ✅ | ✅ | ✅ |
| Changer statut / priorité | | ✅ | ✅ |
| Affecter un ticket | | ✅ | ✅ |
| Voir les statistiques | | ✅ | ✅ |

---

## 🗂️ Structure du projet

```
lib/
├── main.dart                      # Point d'entrée, thème, providers, AuthGate
├── models/
│   ├── user.dart                  # AppUser (client / agent / admin)
│   ├── ticket.dart                # Ticket + Attachment (pièce jointe)
│   ├── comment.dart               # Message de la discussion
│   ├── app_notification.dart      # Notification
│   └── faq_item.dart              # Article de FAQ + score de pertinence
├── services/
│   └── db_service.dart            # Base SQLite : tables, données de démo, requêtes
├── providers/
│   ├── auth_provider.dart         # Connexion, inscription, session
│   ├── ticket_provider.dart       # Tickets, discussion, notifications, stats
│   └── theme_provider.dart        # Mode clair / sombre
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart           # Navigation selon le rôle
│   ├── ticket_list_screen.dart    # Liste + recherche + filtres
│   ├── ticket_detail_screen.dart  # Détail + gestion support + discussion
│   ├── create_ticket_screen.dart  # Formulaire + pièces jointes + assistant
│   ├── faq_screen.dart            # FAQ + assistant automatique
│   ├── admin_dashboard_screen.dart# Statistiques (fl_chart)
│   └── notifications_screen.dart
├── widgets/
│   ├── ticket_card.dart
│   ├── comment_bubble.dart
│   ├── stat_widget.dart
│   ├── status_badge.dart          # Badges statut / priorité
│   └── notification_bell.dart     # Cloche avec badge
└── utils/
    └── constants.dart             # Statuts, priorités, catégories, couleurs, dates
```

---

## 🛢️ Base de données SQLite (`support_client.db`)

```
users          (id, name, email, password [SHA-256], role, created_at)
tickets        (id, title, description, priority, category, status,
                client_id → users, agent_id → users, created_at, updated_at, resolved_at)
attachments    (id, ticket_id → tickets, name, data [BLOB = l'image], created_at)
comments       (id, ticket_id → tickets, user_id → users, message, created_at)
notifications  (id, user_id → users, ticket_id, message, is_read, created_at)
faq            (id, question, answer, keywords)
```

- Les mots de passe sont **hachés en SHA-256** (jamais stockés en clair).
- La session est mémorisée avec `shared_preferences` (l'utilisateur reste connecté).
- Le temps de résolution = `resolved_at - created_at`.

### Voir le contenu de la base
Android Studio → **View → Tool Windows → App Inspection → Database Inspector**
(l'application doit être lancée sur l'émulateur).

### Remettre les données de démo à zéro
Désinstaller l'application de l'émulateur puis relancer `flutter run`.

---

## 📦 Packages utilisés

| Besoin | Package |
|---|---|
| Base de données | `sqflite`, `sqflite_common_ffi_web` (Chrome), `path` |
| Gestion d'état | `provider` |
| Session / préférences | `shared_preferences` |
| Sécurité mots de passe | `crypto` |
| Pièces jointes | `image_picker` |
| Graphiques | `fl_chart` |

> Le sujet propose JWT + API. Ici l'API est remplacée par SQLite (`db_service.dart`)
> et le token par une session locale. Pour passer plus tard à une vraie API REST,
> il suffit de réécrire `db_service.dart` avec `http`/`dio` : les écrans ne changent pas.

---

## 🧪 Tests

```bash
flutter test
```

---

## 🛠️ Problèmes fréquents

- **iOS** : pour la caméra/galerie, ajouter dans `ios/Runner/Info.plist` les clés
  `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription`.
- **Caméra sur émulateur** : utiliser « Galerie » si l'émulateur n'a pas de caméra.
- **Erreur NDK** au build Android : dans `android/app/build.gradle(.kts)`, mettre
  `ndkVersion = "27.0.12077973"` (ou la version indiquée dans le message d'erreur).
- **Erreur de version de package** : lancer `flutter pub upgrade`.

---

## 🎨 Maquette (obligatoire dans le sujet)

La maquette Figma / Balsamiq doit être réalisée et rendue à part.
Écrans à représenter : Connexion → Liste des tickets → Détail + discussion →
Nouveau ticket → FAQ → Statistiques (admin) → Notifications.
