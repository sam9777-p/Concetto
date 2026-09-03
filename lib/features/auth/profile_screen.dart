import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // User Badge
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Guest User',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    'Not Signed In',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Auth Status / Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('SIGN IN / REGISTER'),
              ),
            ),
            const SizedBox(height: 32),
            // Team / Sponsor Drawers
            _buildProfileSection(context, 'Core Team', Icons.group),
            _buildProfileSection(context, 'Sponsors', Icons.card_giftcard),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ListTile(
            title: Text('Detail 1 for $title'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: Text('Detail 2 for $title'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
