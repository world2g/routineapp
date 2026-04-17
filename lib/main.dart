import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'pages/homescreen.dart';
import 'pages/event.dart';
import 'pages/analytics.dart';
import 'pages/notifications.dart';
import 'pages/login_screen.dart';
import 'pages/account.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(), // restore session on launch
      child: const RoutineApp(),
    ),
  );
}

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Routine Planner',
      // theme: ThemeData(
      //   colorSchemeSeed: Colors.blueGrey,
      //   useMaterial3:    true,
      // ),
      // AuthGate decides whether to show the login page or the app
      home: provider.isLoggedIn
            ? const HomePage()
            : const LoginScreen()
    );
  }
}

// ── Auth gate
// Shows a splash/loading screen while restoring the session, then routes to
// LoginScreen or HomePage depending on whether a user is already signed in.

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<AppProvider>();

//     if (provider.isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     if (!provider.isLoggedIn) {
//       return const LoginScreen();
//     }
    
//   }
// }

// ── Main scaffold

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
        title: Text('Routine Planner'),
        centerTitle:true,
        ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Header ──
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blueGrey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(
                      provider.user?.username ?? "User",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),

              // ── Menu Items ──
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text("Notifications"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCentre()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Account"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountCentre()),
                  );
                },
              ),

              const Spacer(),

              // ── Logout ──
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AppProvider>().logout();
                },
              ),

              // ── Close Button ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),

      body: _pages[_currentIndex],

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
