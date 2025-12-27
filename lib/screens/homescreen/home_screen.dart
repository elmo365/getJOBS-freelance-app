import "package:flutter/material.dart";
import 'package:freelance_app/screens/activity/activity.dart';
import 'package:freelance_app/screens/profile/profile.dart';
import 'package:freelance_app/screens/job_seekers/job_seekers_home.dart';
import 'package:freelance_app/screens/employers/employers_home.dart';
import 'package:freelance_app/screens/trainers/trainers_home.dart';
import 'package:freelance_app/screens/admin/admin_panel_screen.dart';
import 'package:freelance_app/screens/search/search_screen.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/auth/user_role_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();

  bool _isLoading = true;
  AppUserRole? _role;

  @override
  void initState() {
    super.initState();
    _resolveRole();
  }

  Future<void> _resolveRole() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc == null || !userDoc.exists) {
        if (!mounted) return;
        setState(() {
          _role = null;
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final role = UserRoleService.fromUserData(userData);

      if (!mounted) return;
      setState(() {
        _role = role;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_role) {
      case AppUserRole.admin:
        return const AdminPanelScreen();
      case AppUserRole.employer:
        return const EmployersHomeScreen();
      case AppUserRole.trainer:
        return const TrainersHomeScreen();
      case AppUserRole.jobSeeker:
      default:
        return const BottomNavigationPage(title: 'Bots Jobs Connect');
    }
  }
}

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key, required this.title});
  final String title;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  late int currentIndex;
  final FirebaseAuthService _authService = FirebaseAuthService();
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    _checkAuth();
  }

  void changePage(int? index) {
    setState(() {
      currentIndex = index!;
    });
  }

  Future<void> _checkAuth() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userId = user.uid;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error checking authentication');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return HintsWrapper(
      screenId: 'home_screen',
      child: Scaffold(
      body: <Widget>[
        const JobSeekersHomeScreen(),
        const Search(),
        const JobsActivity(),
        ProfilePage(
          userID: _userId!,
        ),
      ][currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => changePage(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }
}

