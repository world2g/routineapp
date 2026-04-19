import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'pages/homescreen.dart';
import 'pages/event.dart';
import 'pages/analytics.dart';
import 'pages/login_screen.dart';
import 'pages/account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (provider.isLoading && !provider.isLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!provider.isLoggedIn) return const LoginScreen();
    return const HomePage();
  }
}

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

  bool _lights = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Routine Planner'), centerTitle: true),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              SwitchListTile(
                title: const Text('Notifications'),
                value: _lights,
                onChanged: (bool value) {
                  setState(() {
                    _lights = value;
                  });
                },
                secondary: const Icon(Icons.notifications_none),
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Account Settings"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountCentre()),
                  );
                },
              ),

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
