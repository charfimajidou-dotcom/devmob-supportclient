import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/notification_bell.dart';
import 'admin_dashboard_screen.dart';
import 'create_ticket_screen.dart';
import 'faq_screen.dart';
import 'ticket_list_screen.dart';

/// Écran principal : la navigation change selon le rôle.
/// - Client : Mes tickets / FAQ
/// - Support & Admin : Tous les tickets / Statistiques / FAQ
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      if (user != null) context.read<TicketProvider>().load(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();
    final staff = user.isStaff;

    final pages = <Widget>[
      const TicketListScreen(),
      if (staff) const AdminDashboardScreen(),
      const FaqScreen(),
    ];
    final titles = [
      staff ? 'Tous les tickets' : 'Mes tickets',
      if (staff) 'Statistiques',
      'FAQ & Assistant',
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        selectedIcon: Icon(Icons.confirmation_number),
        label: 'Tickets',
      ),
      if (staff)
        const NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: 'Statistiques',
        ),
      const NavigationDestination(
        icon: Icon(Icons.help_outline),
        selectedIcon: Icon(Icons.help),
        label: 'FAQ',
      ),
    ];
    final i = _index < pages.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[i]),
        actions: [
          const NotificationBell(),
          _menu(user),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: destinations,
      ),
      floatingActionButton: (!staff && i == 0)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau ticket'),
            )
          : null,
    );
  }

  Widget _menu(AppUser user) {
    final dark = context.watch<ThemeProvider>().isDark;
    return PopupMenuButton<String>(
      tooltip: 'Profil',
      icon: CircleAvatar(
        radius: 16,
        child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
      ),
      onSelected: (v) async {
        if (v == 'theme') {
          context.read<ThemeProvider>().toggle();
        } else if (v == 'logout') {
          final auth = context.read<AuthProvider>();
          context.read<TicketProvider>().clear();
          await auth.logout();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(user.isStaff ? Icons.support_agent : Icons.person),
            title: Text(user.name),
            subtitle: Text('${Roles.label(user.role)}\n${user.email}'),
            isThreeLine: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'theme',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            title: Text(dark ? 'Mode clair' : 'Mode sombre'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout),
            title: Text('Se déconnecter'),
          ),
        ),
      ],
    );
  }
}
