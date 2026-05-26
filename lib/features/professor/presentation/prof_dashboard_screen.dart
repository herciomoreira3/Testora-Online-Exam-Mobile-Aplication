import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfDashboardScreen extends StatelessWidget {
  const ProfDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('prof_dashboard')),
        automaticallyImplyLeading: false,
      ),
      body: Center(child: Text(tr('manage_exams'))),
    );
  }
}
