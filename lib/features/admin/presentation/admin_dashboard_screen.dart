import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin_dashboard')),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr('manage_users'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.group),
              label: Text(tr('manage_users')),
              onPressed: () => context.push('/admin/manage-users'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit_calendar),
              label: Text(tr('manage_exams')),
              onPressed: () {
                // Future: navigate to manage exams screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
