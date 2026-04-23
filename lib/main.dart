import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'pages/homescreen.dart';
import 'pages/event.dart';
import 'pages/analytics.dart';
import 'pages/login_screen.dart';
import 'pages/account.dart';
 
// ── Replace with your Supabase project values ──────────────────────────────────
const _supabaseUrl     = 'https://cpoyazafnfsyizpaogsz.supabase.co';
const _supabaseAnonKey = 'sb_publishable_FtARbf9UWdqwXUnrLfD--g_MAdWwQyE';
// ──────────────────────────────────────────────────────────────────────────────
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  await NotificationService.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const RoutineApp(),
    ),
  );
}
 
class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Routine Planner',
      theme: ThemeData(
        colorSchemeSeed: Colors.blueGrey,
        useMaterial3:    true,
      ),
      home: const AuthGate(),
    );
  }
}
 
// ── Auth gate ──────────────────────────────────────────────────────────────────
 
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
 
    if (provider.isLoading && !provider.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
 
    if (!provider.isLoggedIn) return const LoginScreen();
 
    return const HomePage();
  }
}
 
// ── Main scaffold ──────────────────────────────────────────────────────────────
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    AddTaskScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routine Planner'),
        centerTitle: true,
      ),

      // ── Drawer ─────────────────────────────────────────────
      drawer: Drawer(
        child: Column(
          children: [
            // Header
            UserAccountsDrawerHeader(
              accountName: Text(provider.user?.username ?? ''),
              accountEmail: const Text(''), // optional
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),

            // ── Notifications Toggle ─────────────────────────
            SwitchListTile(
              secondary: Icon(
                provider.notificationsEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
              ),
              title: const Text(
                'Push Notifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                provider.notificationsEnabled
                    ? 'Notifications are enabled'
                    : 'Notifications are disabled',
                style: const TextStyle(fontSize: 12),
              ),
              value: provider.notificationsEnabled,
              onChanged: (val) {
                context.read<AppProvider>().toggleNotifications(val);
              },
            ),

            const Divider(),

            // ── Account ──────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Account'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccountScreen()),
                );
              },
            ),

            // ── Logout ───────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                context.read<AppProvider>().logout();
              },
            ),
          ],
        ),
      ),

      // ── Body ───────────────────────────────────────────────
      body: _pages[_currentIndex],

      // ── Bottom Nav ─────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}