import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

class UserRoleService {
  final FirebaseAuthService _authService;
  final FirebaseDatabaseService _dbService;

  UserRoleService({
    FirebaseAuthService? authService,
    FirebaseDatabaseService? dbService,
  })  : _authService = authService ?? FirebaseAuthService(),
        _dbService = dbService ?? FirebaseDatabaseService();

  static AppUserRole fromUserData(Map<String, dynamic> userData) {
    if (userData['isAdmin'] == true) return AppUserRole.admin;

    final userType = (userData['userType'] as String?)?.trim();

    if (userType == 'trainer' || userData['isTrainer'] == true || userData['isMentor'] == true) {
      return AppUserRole.trainer;
    }

    if (userType == 'employer' || userData['isCompany'] == true || userData['isEmployer'] == true) {
      return AppUserRole.employer;
    }

    return AppUserRole.jobSeeker;
  }

  Future<AppUserRole?> getCurrentUserRole() async {
    final user = _authService.getCurrentUser();
    if (user == null) return null;

    final userDoc = await _dbService.getUser(user.uid);
    if (userDoc == null || !userDoc.exists) return null;

    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    return fromUserData(userData);
  }
}
