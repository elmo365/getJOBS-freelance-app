import 'package:flutter/material.dart';
import 'admin_companies_list_screen.dart';

class AdminApprovedCompaniesScreen extends StatelessWidget {
  const AdminApprovedCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminCompaniesListScreen(status: 'approved');
  }
}

