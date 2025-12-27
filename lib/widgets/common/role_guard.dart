import 'package:flutter/material.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/auth/user_role_service.dart';

class RoleGuard extends StatelessWidget {
  final Set<AppUserRole> allow;
  final Widget child;
  final String? title;
  final String? message;

  const RoleGuard({
    super.key,
    required this.allow,
    required this.child,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUserRole?>(
      future: UserRoleService().getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;
        if (role != null && allow.contains(role)) {
          return child;
        }

        return Scaffold(
          appBar: AppBar(title: Text(title ?? 'Access denied')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'Access denied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? 'This area is only available to authorized roles.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
