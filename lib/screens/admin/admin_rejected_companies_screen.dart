import 'package:flutter/material.dart';
import 'admin_companies_list_screen.dart';

class AdminRejectedCompaniesScreen extends StatelessWidget {
  const AdminRejectedCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminCompaniesListScreen(status: 'rejected');
  }
}

