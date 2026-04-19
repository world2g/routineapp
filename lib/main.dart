import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'pages/homescreen.dart';
import 'pages/event.dart';
import 'pages/analytics.dart';
import 'pages/notifications.dart';
import 'pages/login_screen.dart';
import 'pages/account.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        title:       const Text('Routine Planner'),
        centerTitle: true,
        actions: [
          // Notifications bell
          IconButton(
            icon:      const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationCentre()),
            ),
          ),
          // User / account menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (value) {
              if (value == 'account') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              } else if (value == 'logout') {
                context.read<AppProvider>().logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  provider.user?.username ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'account',
                child: Row(children: [
                  Icon(Icons.manage_accounts_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Account'),
                ]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Logout'),
                ]),
              ),
            ],
          ),
        ],
      ),
 
      body: _pages[_currentIndex],
 
      bottomNavigationBar: NavigationBar(
        selectedIndex:          _currentIndex,
        onDestinationSelected:  (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label:        'Home',
          ),
          NavigationDestination(
            icon:  Icon(Icons.add_circle_outline),
            label: 'Add Task',
          ),
          NavigationDestination(
            icon:  Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
 