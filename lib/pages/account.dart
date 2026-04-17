import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import 'package:provider/provider.dart';

class AccountCentre extends StatelessWidget {
  const AccountCentre({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Account",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.person),
              title: Text(provider.user?.username ?? ""),
            ),

            ListTile(
              leading: const Icon(Icons.email),
              title: Text(provider.user?.email ?? ""),
            ),

            const SizedBox(height: 30),

            // Logout
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () {
                provider.logout();
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 10),

            // Delete account (placeholder)
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text("Delete Account"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // TODO: implement delete logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
