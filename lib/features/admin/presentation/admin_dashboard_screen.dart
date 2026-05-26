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
      body: Center(child: Text(tr('manage_users'))),
    );
  }
}
