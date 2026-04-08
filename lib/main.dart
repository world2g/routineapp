import 'package:flutter/material.dart';
import 'pages/homescreen.dart';
import 'pages/event.dart';
import 'pages/analytics.dart';
import 'pages/notifications.dart';

void main() {
  runApp(const RoutineApp());
}

class RoutineApp extends StatelessWidget {
  const RoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    AddTaskScreen(),
    AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        title: const Text("Routine Planner"),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              NotificationCentre();
            },
          ),
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
        ],
      ),

      body: pages[currentPageIndex],

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: "Add Task",
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: "Analytics",
          ),
        ],
      ),
    );
  }
}
