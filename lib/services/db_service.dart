import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_notification.dart';
import '../models/comment.dart';
import '../models/faq_item.dart';
import '../models/ticket.dart';
import '../models/user.dart';

/// Accès à la base SQLite locale (joue le rôle de l'API du projet).
class DbService {
  DbService._();
  static final DbService instance = DbService._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<Database> _open() async {
    // Sur Chrome, la base est stockée dans le navigateur (IndexedDB).
    final path = kIsWeb
        ? 'support_client.db'
        : p.join(await getDatabasesPath(), 'support_client.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createTables(db);
        await _seed(db);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Création des tables
  // -------------------------------------------------------------------------
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE tickets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        client_id INTEGER NOT NULL REFERENCES users(id),
        agent_id INTEGER REFERENCES users(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        resolved_at TEXT
      )''');
    await db.execute('''
      CREATE TABLE attachments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        data BLOB NOT NULL,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_id INTEGER NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id),
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id),
        ticket_id INTEGER,
        message TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE faq(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        keywords TEXT NOT NULL
      )''');
  }

  // -------------------------------------------------------------------------
  // Données de démonstration
  // -------------------------------------------------------------------------
  Future<void> _seed(Database db) async {
    final now = DateTime.now();

    Future<int> user(String name, String email, String pass, String role) =>
        db.insert('users', {
          'name': name,
          'email': email,
          'password': hashPassword(pass),
          'role': role,
          'created_at': now.subtract(const Duration(days: 30)).toIso8601String(),
        });

    final admin = await user('Admin Principal', 'admin@support.tn', 'admin123', 'admin');
    final sami = await user('Sami Ben Ali', 'agent@support.tn', 'agent123', 'agent');
    final leila = await user('Leila Trabelsi', 'leila@support.tn', 'agent123', 'agent');
    final client = await user('Mohamed Client', 'client@support.tn', 'client123', 'client');
    final amira = await user('Amira Saidi', 'amira@support.tn', 'client123', 'client');

    Future<int> ticket({
      required String title,
      required String desc,
      required String cat,
      required String prio,
      required String status,
      required int clientId,
      int? agentId,
      required int daysAgo,
      int? resolvedAfterHours,
    }) {
      final created = now.subtract(Duration(days: daysAgo, hours: 2));
      final resolved =
          resolvedAfterHours == null ? null : created.add(Duration(hours: resolvedAfterHours));
      return db.insert('tickets', {
        'title': title,
        'description': desc,
        'priority': prio,
        'category': cat,
        'status': status,
        'client_id': clientId,
        'agent_id': agentId,
        'created_at': created.toIso8601String(),
        'updated_at': (resolved ?? created).toIso8601String(),
        'resolved_at': resolved?.toIso8601String(),
      });
    }

    Future<void> comment(int ticketId, int userId, String msg, int hoursAgo) async {
      await db.insert('comments', {
        'ticket_id': ticketId,
        'user_id': userId,
        'message': msg,
        'created_at': now.subtract(Duration(hours: hoursAgo)).toIso8601String(),
      });
    }

    Future<void> notif(int userId, int ticketId, String msg) async {
      await db.insert('notifications', {
        'user_id': userId,
        'ticket_id': ticketId,
        'message': msg,
        'is_read': 0,
        'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
      });
    }

    final t1 = await ticket(
      title: 'Impossible de me connecter à mon espace',
      desc: "Depuis hier, je ne peux plus me connecter à mon espace étudiant. "
          "Le message « mot de passe incorrect » s'affiche alors que je n'ai rien changé.",
      cat: 'Connexion / compte',
      prio: 'haute',
      status: 'en_cours',
      clientId: client,
      agentId: sami,
      daysAgo: 2,
    );
    await comment(t1, client, "J'ai essayé sur mon téléphone et sur un PC, même problème.", 40);
    await comment(t1, sami,
        "Bonjour, nous vérifions votre compte. Avez-vous essayé la fonction « Mot de passe oublié » ?", 20);
    await notif(client, t1, 'Sami Ben Ali a répondu au ticket #$t1');

    final t2 = await ticket(
      title: "Demande d'attestation d'inscription",
      desc: "J'ai besoin d'une attestation d'inscription pour l'année en cours (dossier de bourse).",
      cat: 'Demande administrative',
      prio: 'moyenne',
      status: 'resolu',
      clientId: client,
      agentId: leila,
      daysAgo: 6,
      resolvedAfterHours: 20,
    );
    await comment(t2, leila, "Votre attestation est prête, vous pouvez la récupérer à l'accueil.", 120);

    final t3 = await ticket(
      title: 'Wi-Fi très lent en salle B12',
      desc: 'Le Wi-Fi est presque inutilisable en salle B12 depuis lundi, impossible de suivre les TP en ligne.',
      cat: 'Réseau / Internet',
      prio: 'moyenne',
      status: 'nouveau',
      clientId: amira,
      daysAgo: 1,
    );

    final t4 = await ticket(
      title: "Erreur sur ma facture d'octobre",
      desc: 'Le montant de ma facture ne correspond pas à mon abonnement.',
      cat: 'Facturation',
      prio: 'haute',
      status: 'ferme',
      clientId: amira,
      agentId: sami,
      daysAgo: 12,
      resolvedAfterHours: 48,
    );
    await comment(t4, sami, 'La facture a été corrigée et un avoir a été émis. Bonne journée !', 230);

    await ticket(
      title: "L'imprimante du 2e étage ne marche plus",
      desc: "L'imprimante affiche « bourrage papier » en permanence.",
      cat: 'Matériel',
      prio: 'basse',
      status: 'resolu',
      clientId: client,
      agentId: leila,
      daysAgo: 9,
      resolvedAfterHours: 5,
    );

    await ticket(
      title: "L'application de notes plante au démarrage",
      desc: "Depuis la dernière mise à jour, l'application se ferme dès l'ouverture.",
      cat: 'Logiciel',
      prio: 'urgente',
      status: 'en_cours',
      clientId: amira,
      agentId: leila,
      daysAgo: 3,
    );

    final t7 = await ticket(
      title: 'Écran bleu sur le PC du laboratoire',
      desc: 'Le PC n°7 du labo affiche un écran bleu au démarrage.',
      cat: 'Matériel',
      prio: 'urgente',
      status: 'nouveau',
      clientId: client,
      daysAgo: 0,
    );

    await ticket(
      title: 'Accès refusé à la plateforme e-learning',
      desc: "Je n'ai pas accès au cours de Flutter sur la plateforme e-learning.",
      cat: 'Connexion / compte',
      prio: 'moyenne',
      status: 'resolu',
      clientId: amira,
      agentId: sami,
      daysAgo: 15,
      resolvedAfterHours: 30,
    );

    for (final staffId in [admin, sami, leila]) {
      await notif(staffId, t3, 'Nouveau ticket #$t3 : Wi-Fi très lent en salle B12');
      await notif(staffId, t7, 'Nouveau ticket #$t7 : Écran bleu sur le PC du laboratoire');
    }

    // FAQ (keywords séparés par des virgules, sans accents)
    final faq = [
      {
        'question': "J'ai oublié mon mot de passe, que faire ?",
        'answer': "Sur l'écran de connexion de votre espace, cliquez sur « Mot de passe oublié », "
            'saisissez votre e-mail puis suivez le lien reçu. Le lien est valable 24 h.',
        'keywords': 'mot de passe,oublie,password,connecter,connexion,reinitialiser,identifiant',
      },
      {
        'question': 'Mon compte est bloqué, comment le débloquer ?',
        'answer': 'Après 5 tentatives échouées, le compte est bloqué 30 minutes. '
            "Si le blocage persiste, créez un ticket dans la catégorie « Connexion / compte ».",
        'keywords': 'bloque,compte,verrouille,acces,refuse,tentative',
      },
      {
        'question': "Comment obtenir une attestation ou un certificat ?",
        'answer': "Créez un ticket « Demande administrative » en précisant le document voulu. "
            "Il est généralement prêt sous 48 h et à récupérer à l'accueil.",
        'keywords': 'attestation,certificat,document,inscription,releve,scolarite',
      },
      {
        'question': 'Le Wi-Fi ou Internet ne fonctionne pas',
        'answer': 'Oubliez le réseau puis reconnectez-vous avec vos identifiants. '
            'Redémarrez votre appareil. Si le problème touche toute une salle, signalez-la dans un ticket.',
        'keywords': 'wifi,wi-fi,internet,reseau,lent,connexion internet,deconnecte',
      },
      {
        'question': "L'imprimante ne fonctionne pas",
        'answer': "Vérifiez le papier et l'encre, puis éteignez et rallumez l'imprimante. "
            'En cas de bourrage persistant, créez un ticket « Matériel » en indiquant la salle.',
        'keywords': 'imprimante,impression,imprimer,bourrage,papier,encre',
      },
      {
        'question': 'Il y a une erreur sur ma facture',
        'answer': "Créez un ticket « Facturation » en joignant une capture de la facture. "
            "Le service vérifie et émet un avoir si nécessaire.",
        'keywords': 'facture,paiement,montant,rembourse,avoir,prix',
      },
      {
        'question': 'Comment suivre le traitement de mon ticket ?',
        'answer': 'Chaque ticket affiche son statut : Nouveau, En cours, Résolu ou Fermé. '
            'Vous recevez une notification à chaque réponse ou changement de statut.',
        'keywords': 'suivre,statut,ticket,delai,reponse,suivi',
      },
      {
        'question': "Une application plante ou ne s'ouvre pas",
        'answer': "Mettez l'application à jour, videz son cache ou réinstallez-la. "
            'Si le problème continue, créez un ticket « Logiciel » avec une capture du message.',
        'keywords': 'application,plante,crash,bug,ouvre pas,logiciel,erreur,ferme',
      },
    ];
    for (final f in faq) {
      await db.insert('faq', f);
    }
  }

  // -------------------------------------------------------------------------
  // Utilisateurs / authentification
  // -------------------------------------------------------------------------
  Future<AppUser?> login(String email, String password) async {
    final d = await db;
    final rows = await d.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), hashPassword(password)],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> register(String name, String email, String password) async {
    final d = await db;
    final e = email.trim().toLowerCase();
    final exists = await d.query('users', where: 'email = ?', whereArgs: [e]);
    if (exists.isNotEmpty) throw Exception('Cet e-mail est déjà utilisé');
    final now = DateTime.now();
    final id = await d.insert('users', {
      'name': name.trim(),
      'email': e,
      'password': hashPassword(password),
      'role': 'client',
      'created_at': now.toIso8601String(),
    });
    return AppUser(id: id, name: name.trim(), email: e, role: 'client', createdAt: now);
  }

  Future<AppUser?> getUser(int id) async {
    final d = await db;
    final rows = await d.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<List<AppUser>> getUsers() async {
    final d = await db;
    final rows = await d.query('users', orderBy: 'name');
    return rows.map(AppUser.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Tickets
  // -------------------------------------------------------------------------
  static const _ticketSelect = '''
    SELECT t.*, c.name AS client_name, a.name AS agent_name,
      (SELECT COUNT(*) FROM comments m WHERE m.ticket_id = t.id) AS comment_count,
      (SELECT COUNT(*) FROM attachments f WHERE f.ticket_id = t.id) AS attachment_count
    FROM tickets t
    JOIN users c ON c.id = t.client_id
    LEFT JOIN users a ON a.id = t.agent_id''';

  /// Tous les tickets (support) ou seulement ceux d'un client.
  Future<List<Ticket>> getTickets({int? clientId}) async {
    final d = await db;
    final rows = clientId == null
        ? await d.rawQuery('$_ticketSelect ORDER BY t.updated_at DESC')
        : await d.rawQuery(
            '$_ticketSelect WHERE t.client_id = ? ORDER BY t.updated_at DESC', [clientId]);
    return rows.map(Ticket.fromMap).toList();
  }

  Future<int> insertTicket(Ticket t, List<AttachmentData> files) async {
    final d = await db;
    return d.transaction((txn) async {
      final id = await txn.insert('tickets', t.toMap());
      for (final f in files) {
        await txn.insert('attachments', {
          'ticket_id': id,
          'name': f.name,
          'data': f.bytes,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      return id;
    });
  }

  Future<void> updateTicket(int id, Map<String, Object?> values) async {
    final d = await db;
    await d.update(
      'tickets',
      {...values, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Attachment>> getAttachments(int ticketId) async {
    final d = await db;
    final rows = await d.query('attachments', where: 'ticket_id = ?', whereArgs: [ticketId]);
    return rows.map(Attachment.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // Discussion
  // -------------------------------------------------------------------------
  Future<List<TicketComment>> getComments(int ticketId) async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT m.*, u.name AS user_name, u.role AS user_role
      FROM comments m JOIN users u ON u.id = m.user_id
      WHERE m.ticket_id = ?
      ORDER BY m.created_at ASC, m.id ASC''', [ticketId]);
    return rows.map(TicketComment.fromMap).toList();
  }

  Future<void> addComment(int ticketId, int userId, String message) async {
    final d = await db;
    final now = DateTime.now().toIso8601String();
    await d.insert('comments', {
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'created_at': now,
    });
    await d.update('tickets', {'updated_at': now}, where: 'id = ?', whereArgs: [ticketId]);
  }

  // -------------------------------------------------------------------------
  // Notifications
  // -------------------------------------------------------------------------
  Future<void> addNotification(int userId, int? ticketId, String message) async {
    final d = await db;
    await d.insert('notifications', {
      'user_id': userId,
      'ticket_id': ticketId,
      'message': message,
      'is_read': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AppNotification>> getNotifications(int userId) async {
    final d = await db;
    final rows = await d.query('notifications',
        where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC, id DESC');
    return rows.map(AppNotification.fromMap).toList();
  }

  Future<void> markNotificationRead(int id) async {
    final d = await db;
    await d.update('notifications', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAllNotificationsRead(int userId) async {
    final d = await db;
    await d.update('notifications', {'is_read': 1}, where: 'user_id = ?', whereArgs: [userId]);
  }

  // -------------------------------------------------------------------------
  // FAQ
  // -------------------------------------------------------------------------
  Future<List<FaqItem>> getFaq() async {
    final d = await db;
    final rows = await d.query('faq', orderBy: 'id');
    return rows.map(FaqItem.fromMap).toList();
  }
}
