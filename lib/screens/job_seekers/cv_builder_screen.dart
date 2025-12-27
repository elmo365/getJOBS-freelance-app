import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/models/cv_model.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/services/ai/gemini_ai_service.dart';
import 'package:freelance_app/services/ai/context_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';

class CVBuilderScreen extends StatefulWidget {
  const CVBuilderScreen({super.key});

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen>
    with ConnectivityAware {
  final _authService = FirebaseAuthService();
  final _dbService = FirebaseDatabaseService();
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _isSearchable = true;

  // User profile data (loaded from profile)
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  // Form controllers
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _skillsFormKey = GlobalKey<FormState>();

  // Personal Info - removed name/email (from profile)
  final _professionalTitleController = TextEditingController();
  final _linkedInController = TextEditingController();
  final _portfolioController = TextEditingController();

  final List<Education> _educationList = [];
  final List<Experience> _experienceList = [];
  final List<String> _skills = [];
  final List<Language> _languages = []; // New: Languages with proficiency
  final List<Certification> _certifications =
      []; // New: Detailed certifications
  final List<Project> _projects = []; // New: Projects/Portfolio
  String? _summary;

  // Inline form visibility states (no more popups)
  bool _showEducationForm = false;
  bool _showExperienceForm = false;
  bool _showLanguageForm = false;
  bool _showCertificationForm = false;
  bool _showProjectForm = false;

  // Education form controllers
  final _eduInstitutionController = TextEditingController();
  final _eduDegreeController = TextEditingController();
  final _eduFieldController = TextEditingController();
  final _eduStartController = TextEditingController();
  final _eduEndController = TextEditingController();
  final _eduDescController = TextEditingController();
  final _eduFormKey = GlobalKey<FormState>();
  String? _eduType = 'formal';

  // Experience form controllers
  final _expCompanyController = TextEditingController();
  final _expPositionController = TextEditingController();
  final _expStartController = TextEditingController();
  final _expEndController = TextEditingController();
  final _expFormKey = GlobalKey<FormState>();

  // Language form controllers
  final _langNameController = TextEditingController();
  String _langProficiency = 'intermediate';
  final _langFormKey = GlobalKey<FormState>();

  // Certification form controllers
  final _certNameController = TextEditingController();
  final _certIssuerController = TextEditingController();
  final _certIssueDateController = TextEditingController();
  final _certExpiryController = TextEditingController();
  final _certCredentialController = TextEditingController();
  final _certFormKey = GlobalKey<FormState>();

  // Project form controllers
  final _projNameController = TextEditingController();
  final _projDescController = TextEditingController();
  final _projUrlController = TextEditingController();
  final _projStartController = TextEditingController();
  final _projEndController = TextEditingController();
  final _projFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCV();
  }

  Future<void> _loadCV() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final cvDoc = await _dbService.getCVByUserId(user.uid);
      if (cvDoc != null && cvDoc.exists) {
        final Map<String, dynamic> data = cvDoc.data() as Map<String, dynamic>;
        // Use CVModel.fromMap to strictly type the data handling
        final cv = CVModel.fromMap(data, cvDoc.id);

        if (mounted) {
          setState(() {
            // Personal Info
            _professionalTitleController.text =
                cv.personalInfo.professionalTitle ?? '';
            _linkedInController.text = cv.personalInfo.linkedIn ?? '';
            _portfolioController.text = cv.personalInfo.portfolio ?? '';

            // Lists
            _educationList.clear();
            _educationList.addAll(cv.education);

            _experienceList.clear();
            _experienceList.addAll(cv.experience);

            _skills.clear();
            _skills.addAll(cv.skills);

            _languages.clear();
            _languages.addAll(cv.languages);

            _certifications.clear();
            _certifications.addAll(cv.certifications);

            _projects.clear();
            _projects.addAll(cv.projects);

            // Other fields
            _summary = cv.summary;
            _isSearchable = cv.isSearchable;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading CV: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'Error loading your CV data');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) setState(() => _isLoadingProfile = false);
        return;
      }

      final userDoc = await _dbService.getUser(user.uid);
      if (userDoc != null && mounted) {
        setState(() {
          _userProfile = userDoc.data() as Map<String, dynamic>? ?? {};
          _isLoadingProfile = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  // Validation methods
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal Info
        return _personalInfoFormKey.currentState?.validate() ?? false;
      case 1: // Education
        // At least one education entry OR allow skipping if user has experience
        return _educationList.isNotEmpty || _experienceList.isNotEmpty;
      case 2: // Experience
        // At least one experience entry OR allow skipping if user has education
        return _experienceList.isNotEmpty || _educationList.isNotEmpty;
      case 3: // Skills & Summary
        return (_summary != null && _summary!.trim().length >= 50) &&
            _skills.length >= 3;
      default:
        return false;
    }
  }

  @override
  void dispose() {
    _professionalTitleController.dispose();
    _linkedInController.dispose();
    _portfolioController.dispose();
    _pageController.dispose();
    // Education form controllers
    _eduInstitutionController.dispose();
    _eduDegreeController.dispose();
    _eduFieldController.dispose();
    _eduStartController.dispose();
    _eduEndController.dispose();
    _eduDescController.dispose();
    // Experience form controllers
    _expCompanyController.dispose();
    _expPositionController.dispose();
    _expStartController.dispose();
    _expEndController.dispose();
    // Language form controllers
    _langNameController.dispose();
    // Certification form controllers
    _certNameController.dispose();
    _certIssuerController.dispose();
    _certIssueDateController.dispose();
    _certExpiryController.dispose();
    _certCredentialController.dispose();
    // Project form controllers
    _projNameController.dispose();
    _projDescController.dispose();
    _projUrlController.dispose();
    _projStartController.dispose();
    _projEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in Builder to catch any build errors
    return Builder(
      builder: (context) {
        try {
          return HintsWrapper(
            screenId: 'cv_builder',
            child: Scaffold(
              backgroundColor: AppDesignSystem.surface(context),
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: Column(
                  children: [
                    // Persistent Header with Title and Steps
                    Container(
                      decoration: BoxDecoration(
                        color: AppDesignSystem.surface(context),
                        border: Border(
                          bottom: BorderSide(
                            color: AppDesignSystem.outlineVariant(context)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Custom App Bar Row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: Text(
                                    'Digital CV Builder',
                                    style: AppDesignSystem.titleMedium(context)
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                MicroInteractions.scaleCard(
                                  child: IconButton(
                                    icon: const Icon(Icons.preview_outlined),
                                    tooltip: 'Preview CV',
                                    onPressed: _showCvPreview,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Compact Step Indicator
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCompactStep(0, 'Personal'),
                                _buildStepConnector(0),
                                _buildCompactStep(1, 'Education'),
                                _buildStepConnector(1),
                                _buildCompactStep(2, 'Experience'),
                                _buildStepConnector(2),
                                _buildCompactStep(3, 'Skills'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: AppDesignSystem.paddingM,
                        child: Column(
                          children: [
                            // Current Step Content
                            _buildCurrentStepContent(),

                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceL),

                            // Navigation Buttons (Inline)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentStep > 0)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _currentStep--;
                                      });
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Previous'),
                                  )
                                else
                                  const SizedBox.shrink(),
                                FilledButton.icon(
                                  onPressed: _onNextPressed,
                                  icon: Icon(_currentStep < 3
                                      ? Icons.arrow_forward
                                      : Icons.save),
                                  label: Text(
                                      _currentStep < 3 ? 'Next' : 'Save CV'),
                                ),
                              ],
                            ),
                            // Extra padding for bottom safety
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceXL),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (e, stackTrace) {
          debugPrint('CV Builder build error: $e');
          debugPrint('Stack trace: $stackTrace');
          return const Scaffold(
            body: Center(child: Text('Error loading CV Builder')),
          );
        }
      },
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildEducationStep();
      case 2:
        return _buildExperienceStep();
      case 3:
        return _buildSkillsStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  void _onNextPressed() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      } else {
        _showValidationMessage();
      }
    } else {
      if (_validateCurrentStep()) {
        _saveCV();
      } else {
        _showValidationMessage();
      }
    }
  }

  void _showValidationMessage() {
    String errorMsg = 'Please complete all required fields';
    if (_currentStep == 0) {
      errorMsg = 'Please enter your professional title';
    } else if (_currentStep == 1) {
      errorMsg = 'Please add at least one education entry or work experience';
    } else if (_currentStep == 2) {
      errorMsg = 'Please add at least one work experience or education entry';
    } else if (_currentStep == 3) {
      errorMsg = 'Please add at least 3 skills and a summary (min 50 chars)';
    }
    SnackbarHelper.showError(context, errorMsg);
  }

  Widget _buildCompactStep(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    final color = isActive || isCompleted
        ? AppDesignSystem.primary(context)
        : AppDesignSystem.outlineVariant(context);

    return InkWell(
      onTap: () {
        // Optional: Allow jumping to completed steps
        if (isCompleted) {
          setState(() => _currentStep = step);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: isActive ? 1.5 : 1),
        ),
        child: Row(
          children: [
            if (isCompleted)
              Icon(Icons.check, size: 14, color: color)
            else
              Text('${step + 1}',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = step < _currentStep;
    return Container(
      width: 16,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isCompleted
          ? AppDesignSystem.primary(context)
          : AppDesignSystem.outlineVariant(context).withValues(alpha: 0.3),
    );
  }

  Widget _buildPersonalInfoStep() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    final userName = _userProfile?['name'] ?? 'User';
    final userEmail = _userProfile?['email'] ?? '';
    final userPhone = _userProfile?['phone_number'] ?? '';
    final userAddress = _userProfile?['address'] ?? '';

    return SingleChildScrollView(
      padding: AppDesignSystem.paddingM,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _personalInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            // Display profile info (read-only)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From Your Profile',
                    style: AppDesignSystem.labelSmall(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  _buildProfileInfoRow(Icons.person, 'Name', userName),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                  _buildProfileInfoRow(Icons.email, 'Email', userEmail),
                  if (userPhone.isNotEmpty) ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    _buildProfileInfoRow(Icons.phone, 'Phone', userPhone),
                  ],
                  if (userAddress.isNotEmpty) ...[
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    _buildProfileInfoRow(
                        Icons.location_on, 'Address', userAddress),
                  ],
                ],
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            // Professional Title (required)
            _buildModernTextField(
              controller: _professionalTitleController,
              label: 'Professional Title/Headline *',
              hintText: 'e.g., Software Developer, Marketing Specialist',
              prefixIcon: Icons.work_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your professional title';
                }
                if (value.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            // LinkedIn and Portfolio (optional but recommended)
            Row(
              children: [
                Expanded(
                  child: _buildModernTextField(
                    controller: _linkedInController,
                    label: 'LinkedIn Profile',
                    hintText: 'linkedin.com/in/...',
                    prefixIcon: Icons.link,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!value.contains('linkedin.com')) {
                          return 'Please enter a valid LinkedIn URL';
                        }
                        return InputValidators.validateURL(value);
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spaceM),
                Expanded(
                  child: _buildModernTextField(
                    controller: _portfolioController,
                    label: 'Portfolio/Website',
                    hintText: 'yourwebsite.com',
                    prefixIcon: Icons.web,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        return InputValidators.validateURL(value);
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
        Text(
          '$label: ',
          style: AppDesignSystem.bodySmall(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppDesignSystem.bodySmall(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationStep() {
    return SingleChildScrollView(
      padding: AppDesignSystem.paddingM,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Education',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_showEducationForm)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    setState(() => _showEducationForm = true);
                  },
                  tooltip: 'Add Education',
                ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            'Add your education background. This can include formal education, online courses, self-taught skills, workshops, or certifications.',
            style: AppDesignSystem.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

          // Inline Education Form (no popup)
          if (_showEducationForm) _buildInlineEducationForm(),

          if (_educationList.isEmpty && !_showEducationForm)
            Center(
              child: Padding(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      'No education added yet',
                      style: AppDesignSystem.bodyMedium(context),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      'Tap + to add your education',
                      style: AppDesignSystem.bodySmall(context).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_educationList.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _educationList.length,
              itemBuilder: (context, index) {
                final education = _educationList[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      education.degree ?? education.institution,
                      style: AppDesignSystem.titleSmall(context),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (education.educationType != null)
                          Chip(
                            label: Text(
                              _getEducationTypeLabel(education.educationType),
                              style: AppDesignSystem.labelSmall(context),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (education.degree != null &&
                            education.institution.isNotEmpty)
                          Text(education.institution),
                        if (education.fieldOfStudy != null)
                          Text('Field: ${education.fieldOfStudy}'),
                        if (education.description != null)
                          Text(
                            education.description!,
                            style: AppDesignSystem.bodySmall(context),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (education.startDate != null ||
                            education.endDate != null)
                          Text(
                            '${education.startDate ?? "?"} - ${education.endDate ?? "Present"}',
                            style: AppDesignSystem.bodySmall(context),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _educationList.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Inline education form (replaces popup dialog)
  Widget _buildInlineEducationForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Form(
          key: _eduFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Education',
                    style: AppDesignSystem.titleMedium(context).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _clearEducationForm();
                      setState(() => _showEducationForm = false);
                    },
                  ),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              // Education Type Dropdown
              const Text(
                'Education Type *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _eduType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: AppDesignSystem.borderRadiusM,
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'formal',
                      child: Text('Formal Education (University, College)')),
                  DropdownMenuItem(
                      value: 'online', child: Text('Online Course / MOOC')),
                  DropdownMenuItem(
                      value: 'self-taught',
                      child: Text('Self-Taught / Independent Learning')),
                  DropdownMenuItem(
                      value: 'workshop',
                      child: Text('Workshop / Training Program')),
                  DropdownMenuItem(
                      value: 'certification',
                      child: Text('Professional Certification')),
                ],
                onChanged: (value) => setState(() => _eduType = value),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _eduInstitutionController,
                label: _eduType == 'self-taught'
                    ? 'Learning Platform / Resource *'
                    : 'Institution / Platform *',
                hintText: _eduType == 'self-taught'
                    ? 'e.g., YouTube, Books, Online Resources'
                    : 'e.g., University Name, Coursera, etc.',
                prefixIcon: Icons.school,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter an institution or platform'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              if (_eduType == 'formal' || _eduType == 'certification')
                _buildModernTextField(
                  controller: _eduDegreeController,
                  label: _eduType == 'certification'
                      ? 'Certification Name'
                      : 'Degree / Qualification',
                  hintText: _eduType == 'certification'
                      ? 'e.g., AWS Certified Solutions Architect'
                      : 'e.g., Bachelor of Science, Diploma',
                  prefixIcon: Icons.workspace_premium,
                ),
              if (_eduType == 'formal') ...[
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _eduFieldController,
                  label: 'Field of Study',
                  hintText: 'e.g., Computer Science, Business Administration',
                  prefixIcon: Icons.menu_book,
                ),
              ],
              if (_eduType != 'formal') ...[
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildModernTextField(
                  controller: _eduDescController,
                  label: 'Description / What You Learned',
                  hintText: 'Describe what you learned or achieved',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),
              ],
              if (_eduType != 'self-taught') ...[
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildDatePicker(
                    context: context,
                    controller: _eduStartController,
                    label: 'Start Date'),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                _buildDatePicker(
                    context: context,
                    controller: _eduEndController,
                    label: 'End Date (Optional)'),
              ],
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _clearEducationForm();
                      setState(() => _showEducationForm = false);
                    },
                    child: Text('Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  ElevatedButton(
                    onPressed: () {
                      if (!(_eduFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() {
                        _educationList.add(Education(
                          institution: _eduInstitutionController.text.trim(),
                          degree: _eduDegreeController.text.trim().isEmpty
                              ? null
                              : _eduDegreeController.text.trim(),
                          fieldOfStudy: _eduFieldController.text.trim().isEmpty
                              ? null
                              : _eduFieldController.text.trim(),
                          startDate: _eduStartController.text.trim().isEmpty
                              ? null
                              : _eduStartController.text.trim(),
                          endDate: _eduEndController.text.trim().isEmpty
                              ? null
                              : _eduEndController.text.trim(),
                          description: _eduDescController.text.trim().isEmpty
                              ? null
                              : _eduDescController.text.trim(),
                          educationType: _eduType,
                        ));
                        _clearEducationForm();
                        _showEducationForm = false;
                      });
                    },
                    child: const Text('Add Education'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearEducationForm() {
    _eduInstitutionController.clear();
    _eduDegreeController.clear();
    _eduFieldController.clear();
    _eduStartController.clear();
    _eduEndController.clear();
    _eduDescController.clear();
    _eduType = 'formal';
  }

  Widget _buildExperienceStep() {
    return SingleChildScrollView(
      padding: AppDesignSystem.paddingM,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Work Experience',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_showExperienceForm)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () {
                    setState(() => _showExperienceForm = true);
                  },
                  tooltip: 'Add Experience',
                ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            'Add your work experience, internships, or freelance projects.',
            style: AppDesignSystem.bodySmall(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),

          // Inline Experience Form (no popup)
          if (_showExperienceForm) _buildInlineExperienceForm(),

          if (_experienceList.isEmpty && !_showExperienceForm)
            Center(
              child: Padding(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                    Text(
                      'No experience added yet',
                      style: AppDesignSystem.bodyMedium(context),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                    Text(
                      'Tap + to add your work experience',
                      style: AppDesignSystem.bodySmall(context).copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_experienceList.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _experienceList.length,
              itemBuilder: (context, index) {
                final experience = _experienceList[index];
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      experience.position,
                      style: AppDesignSystem.titleSmall(context),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(experience.company),
                        if (experience.startDate != null ||
                            experience.endDate != null)
                          Text(
                            '${experience.startDate ?? "?"} - ${experience.isCurrent ? "Present" : (experience.endDate ?? "?")}',
                            style: AppDesignSystem.bodySmall(context),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _experienceList.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Inline experience form (replaces popup dialog)
  Widget _buildInlineExperienceForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Form(
          key: _expFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Experience',
                    style: AppDesignSystem.titleMedium(context)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _clearExperienceForm();
                      setState(() => _showExperienceForm = false);
                    },
                  ),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _expCompanyController,
                label: 'Company *',
                hintText: 'e.g., Google, Microsoft',
                prefixIcon: Icons.business,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a company name'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _expPositionController,
                label: 'Position *',
                hintText: 'e.g., Software Engineer',
                prefixIcon: Icons.work,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter your position'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _expStartController,
                  label: 'Start Date'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _expEndController,
                  label: 'End Date (leave empty if current)'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _clearExperienceForm();
                      setState(() => _showExperienceForm = false);
                    },
                    child: Text('Cancel',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  ElevatedButton(
                    onPressed: () {
                      if (!(_expFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() {
                        _experienceList.add(Experience(
                          company: _expCompanyController.text.trim(),
                          position: _expPositionController.text.trim(),
                          startDate: _expStartController.text.trim().isEmpty
                              ? null
                              : _expStartController.text.trim(),
                          endDate: _expEndController.text.trim().isEmpty
                              ? null
                              : _expEndController.text.trim(),
                          isCurrent: _expEndController.text.trim().isEmpty,
                        ));
                        _clearExperienceForm();
                        _showExperienceForm = false;
                      });
                    },
                    child: const Text('Add Experience'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearExperienceForm() {
    _expCompanyController.clear();
    _expPositionController.clear();
    _expStartController.clear();
    _expEndController.clear();
  }

  /// Inline language form (replaces popup dialog)
  Widget _buildInlineLanguageForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Form(
          key: _langFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Language',
                      style: AppDesignSystem.titleMedium(context)
                          .copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearLanguageForm();
                        setState(() => _showLanguageForm = false);
                      }),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _langNameController,
                label: 'Language *',
                hintText: 'e.g., English, French, Mandarin',
                prefixIcon: Icons.language,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a language'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              const Text('Proficiency *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _langProficiency,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.bar_chart),
                  border: OutlineInputBorder(
                      borderRadius: AppDesignSystem.borderRadiusM),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('Basic')),
                  DropdownMenuItem(
                      value: 'intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  DropdownMenuItem(
                      value: 'native', child: Text('Native / Fluent')),
                ],
                onChanged: (value) =>
                    setState(() => _langProficiency = value ?? 'intermediate'),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        _clearLanguageForm();
                        setState(() => _showLanguageForm = false);
                      },
                      child: Text('Cancel',
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant))),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  ElevatedButton(
                    onPressed: () {
                      if (!(_langFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() {
                        _languages.add(Language(
                            name: _langNameController.text.trim(),
                            proficiency: _langProficiency));
                        _clearLanguageForm();
                        _showLanguageForm = false;
                      });
                    },
                    child: const Text('Add Language'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearLanguageForm() {
    _langNameController.clear();
    _langProficiency = 'intermediate';
  }

  /// Inline certification form (replaces popup dialog)
  Widget _buildInlineCertificationForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Form(
          key: _certFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Certification',
                      style: AppDesignSystem.titleMedium(context)
                          .copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearCertificationForm();
                        setState(() => _showCertificationForm = false);
                      }),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _certNameController,
                label: 'Certification Name *',
                hintText: 'e.g., AWS Solutions Architect',
                prefixIcon: Icons.verified,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a certification name'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                  controller: _certIssuerController,
                  label: 'Issuing Organization',
                  hintText: 'e.g., Amazon, Google, Microsoft',
                  prefixIcon: Icons.business),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _certIssueDateController,
                  label: 'Issue Date'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _certExpiryController,
                  label: 'Expiry Date (Optional)'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                  controller: _certCredentialController,
                  label: 'Credential ID (Optional)',
                  hintText: 'e.g., ABC123XYZ',
                  prefixIcon: Icons.badge),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        _clearCertificationForm();
                        setState(() => _showCertificationForm = false);
                      },
                      child: Text('Cancel',
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant))),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  ElevatedButton(
                    onPressed: () {
                      if (!(_certFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() {
                        _certifications.add(Certification(
                          name: _certNameController.text.trim(),
                          issuer: _certIssuerController.text.trim().isEmpty
                              ? null
                              : _certIssuerController.text.trim(),
                          issueDate:
                              _certIssueDateController.text.trim().isEmpty
                                  ? null
                                  : _certIssueDateController.text.trim(),
                          expiryDate: _certExpiryController.text.trim().isEmpty
                              ? null
                              : _certExpiryController.text.trim(),
                          credentialId:
                              _certCredentialController.text.trim().isEmpty
                                  ? null
                                  : _certCredentialController.text.trim(),
                        ));
                        _clearCertificationForm();
                        _showCertificationForm = false;
                      });
                    },
                    child: const Text('Add Certification'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearCertificationForm() {
    _certNameController.clear();
    _certIssuerController.clear();
    _certIssueDateController.clear();
    _certExpiryController.clear();
    _certCredentialController.clear();
  }

  /// Inline project form (replaces popup dialog)
  Widget _buildInlineProjectForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      child: Padding(
        padding: AppDesignSystem.paddingM,
        child: Form(
          key: _projFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Project',
                      style: AppDesignSystem.titleMedium(context)
                          .copyWith(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _clearProjectForm();
                        setState(() => _showProjectForm = false);
                      }),
                ],
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                controller: _projNameController,
                label: 'Project Name *',
                hintText: 'e.g., E-commerce Platform',
                prefixIcon: Icons.folder,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a project name'
                    : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                  controller: _projDescController,
                  label: 'Description',
                  hintText: 'Brief description of the project',
                  prefixIcon: Icons.description,
                  maxLines: 3),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildModernTextField(
                  controller: _projUrlController,
                  label: 'Project URL (Optional)',
                  hintText: 'e.g., https://github.com/...',
                  prefixIcon: Icons.link),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _projStartController,
                  label: 'Start Date'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              _buildDatePicker(
                  context: context,
                  controller: _projEndController,
                  label: 'End Date (Optional)'),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        _clearProjectForm();
                        setState(() => _showProjectForm = false);
                      },
                      child: Text('Cancel',
                          style:
                              TextStyle(color: colorScheme.onSurfaceVariant))),
                  AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                  ElevatedButton(
                    onPressed: () {
                      if (!(_projFormKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      setState(() {
                        _projects.add(Project(
                          name: _projNameController.text.trim(),
                          description: _projDescController.text.trim().isEmpty
                              ? null
                              : _projDescController.text.trim(),
                          url: _projUrlController.text.trim().isEmpty
                              ? null
                              : _projUrlController.text.trim(),
                          startDate: _projStartController.text.trim().isEmpty
                              ? null
                              : _projStartController.text.trim(),
                          endDate: _projEndController.text.trim().isEmpty
                              ? null
                              : _projEndController.text.trim(),
                        ));
                        _clearProjectForm();
                        _showProjectForm = false;
                      });
                    },
                    child: const Text('Add Project'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearProjectForm() {
    _projNameController.clear();
    _projDescController.clear();
    _projUrlController.clear();
    _projStartController.clear();
    _projEndController.clear();
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: AppDesignSystem.paddingM,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _skillsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Skills & Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            const Text(
              'Skills *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              'Add at least 3 skills. Tap a skill to remove it.',
              style: AppDesignSystem.bodySmall(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () {
                    setState(() {
                      _skills.remove(skill);
                    });
                  },
                );
              }).toList(),
            ),
            if (_skills.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Add ${3 - _skills.length} more skill(s)',
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Add a skill and press Enter',
                prefixIcon: Icon(Icons.add),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty &&
                    !_skills.contains(value.trim())) {
                  setState(() {
                    _skills.add(value.trim());
                  });
                }
              },
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            const Text(
              'Professional Summary *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              'Write a brief summary about yourself (minimum 50 characters)',
              style: AppDesignSystem.bodySmall(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            TextFormField(
              initialValue: _summary,
              decoration: const InputDecoration(
                hintText: 'Write a brief summary about yourself...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) {
                _summary = value;
              },
              validator: (value) {
                if (value == null || value.trim().length < 50) {
                  return 'Summary must be at least 50 characters';
                }
                return null;
              },
            ),
            if (_summary != null && _summary!.trim().length < 50)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${50 - _summary!.trim().length} more characters needed',
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            // Languages Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Languages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_showLanguageForm)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => setState(() => _showLanguageForm = true),
                    tooltip: 'Add Language',
                  ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            if (_showLanguageForm) _buildInlineLanguageForm(),
            if (_languages.isEmpty && !_showLanguageForm)
              Text(
                'No languages added yet',
                style: AppDesignSystem.bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (_languages.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages.asMap().entries.map((entry) {
                  final lang = entry.value;
                  return Chip(
                    label: Text('${lang.name} (${lang.proficiency})'),
                    onDeleted: () {
                      setState(() {
                        _languages.removeAt(entry.key);
                      });
                    },
                  );
                }).toList(),
              ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            // Certifications Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Certifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_showCertificationForm)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () =>
                        setState(() => _showCertificationForm = true),
                    tooltip: 'Add Certification',
                  ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            if (_showCertificationForm) _buildInlineCertificationForm(),
            if (_certifications.isEmpty && !_showCertificationForm)
              Text(
                'No certifications added yet',
                style: AppDesignSystem.bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (_certifications.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _certifications.length,
                itemBuilder: (context, index) {
                  final cert = _certifications[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(cert.name),
                      subtitle: cert.issuer != null ? Text(cert.issuer!) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _certifications.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            // Projects/Portfolio Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Projects / Portfolio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_showProjectForm)
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => setState(() => _showProjectForm = true),
                    tooltip: 'Add Project',
                  ),
              ],
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            if (_showProjectForm) _buildInlineProjectForm(),
            if (_projects.isEmpty && !_showProjectForm)
              Text(
                'No projects added yet',
                style: AppDesignSystem.bodySmall(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (_projects.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(project.name),
                      subtitle: project.description != null
                          ? Text(
                              project.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _projects.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            SwitchListTile(
              title: const Text('Make Profile Searchable'),
              subtitle: const Text(
                  'Allow employers to find your profile through AI recommendations when you match their job requirements.'),
              value: _isSearchable,
              onChanged: (value) {
                setState(() {
                  _isSearchable = value;
                });
              },
              activeThumbColor: Colors.blue,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  // Old popup dialog methods removed - using inline forms now
  // See _buildInlineEducationForm, _buildInlineExperienceForm, etc.

  void _showCvPreview() {
    // Get data from profile and form
    final name = _userProfile?['name'] ?? 'User';
    final email = _userProfile?['email'] ?? '';
    final phone = _userProfile?['phone_number'] ?? '';
    final address = _userProfile?['address'] ?? '';
    final linkedIn = _linkedInController.text.trim();
    final portfolio = _portfolioController.text.trim();
    final professionalTitle = _professionalTitleController.text.trim();
    final summary = (_summary ?? '').trim();

    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          insetPadding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          scrollable: true,
          title: const Text('CV Preview'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name.isEmpty ? 'Name not set' : name,
                    style: theme.textTheme.titleLarge),
                if (professionalTitle.isNotEmpty) ...[
                  AppDesignSystem.verticalSpace(4),
                  Text(professionalTitle, style: theme.textTheme.titleMedium),
                ],
                AppDesignSystem.verticalSpace(6),
                if (email.isNotEmpty) Text(email),
                if (phone.isNotEmpty) Text(phone),
                if (address.isNotEmpty) Text(address),
                if (linkedIn.isNotEmpty) Text('LinkedIn: $linkedIn'),
                if (portfolio.isNotEmpty) Text('Portfolio: $portfolio'),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                if (summary.isNotEmpty) ...[
                  Text('Summary', style: theme.textTheme.titleMedium),
                  AppDesignSystem.verticalSpace(6),
                  Text(summary),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                ],
                Text('Skills', style: theme.textTheme.titleMedium),
                AppDesignSystem.verticalSpace(6),
                _skills.isEmpty
                    ? const Text('No skills added')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills
                            .map((s) => Chip(label: Text(s)))
                            .toList(growable: false),
                      ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text('Education', style: theme.textTheme.titleMedium),
                AppDesignSystem.verticalSpace(6),
                _educationList.isEmpty
                    ? const Text('No education added')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _educationList
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.degree ?? 'Degree'),
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceXS),
                                      Text(e.institution),
                                    ],
                                  ),
                                ))
                            .toList(growable: false),
                      ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                Text('Experience', style: theme.textTheme.titleMedium),
                AppDesignSystem.verticalSpace(6),
                _experienceList.isEmpty
                    ? const Text('No experience added')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _experienceList
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(e.position),
                                      AppDesignSystem.verticalSpace(
                                          AppDesignSystem.spaceXS),
                                      Text(e.company),
                                    ],
                                  ),
                                ))
                            .toList(growable: false),
                      ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: AppDesignSystem.buttonText(context).copyWith(
                  color: AppDesignSystem.primary(context),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCV() async {
    // Check connectivity
    if (!await checkConnectivity(context,
        message:
            'Cannot save CV without internet. Please connect and try again.')) {
      return;
    }

    if (!mounted) return;

    // Validate required fields
    if (_professionalTitleController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Please enter your professional title');
      return;
    }
    if (_summary == null || _summary!.trim().length < 50) {
      SnackbarHelper.showError(
          context, 'Please add a professional summary (min 50 characters)');
      return;
    }
    if (_skills.length < 3) {
      SnackbarHelper.showError(context, 'Please add at least 3 skills');
      return;
    }

    // Show loading indicator

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        SnackbarHelper.showError(context, 'Please login to save your CV');
        return;
      }

      // Get profile data
      final userName = _userProfile?['name'] ?? '';
      final userEmail = _userProfile?['email'] ?? '';
      final userPhone = _userProfile?['phone_number'] ?? '';
      final userAddress = _userProfile?['address'] ?? '';

      // Create CVModel structure
      final personalInfo = PersonalInfo(
        fullName: userName,
        email: userEmail,
        phone: userPhone,
        address: userAddress,
        linkedIn: _linkedInController.text.trim().isEmpty
            ? null
            : _linkedInController.text.trim(),
        portfolio: _portfolioController.text.trim().isEmpty
            ? null
            : _portfolioController.text.trim(),
        professionalTitle: _professionalTitleController.text.trim().isEmpty
            ? null
            : _professionalTitleController.text.trim(),
      );

      // Create CVModel
      final cvModel = CVModel(
        cvId: '', // Will be set by createCV
        userId: user.uid,
        personalInfo: personalInfo,
        education: _educationList,
        experience: _experienceList,
        skills: _skills,
        languages: _languages,
        certifications: _certifications,
        projects: _projects,
        summary: _summary,
        isSearchable: _isSearchable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert to map for saving (using CVModel's toMap)
      final cvData = cvModel.toMap();
      cvData['user_id'] = user.uid; // Ensure user_id is set
      cvData['userId'] = user.uid; // Ensure userId is also set for consistency

      // Check if CV already exists for this user
      final existingCV = await _dbService.getCVByUserId(user.uid);
      String? cvId;

      if (existingCV != null && existingCV.exists) {
        // Update existing CV
        cvId = existingCV.id;
        cvData.remove('cvId'); // Remove cvId from update data
        cvData.remove('createdAt'); // Don't update createdAt
        await _dbService.updateCV(
          cvId: cvId,
          data: cvData,
        );
        debugPrint('CV updated successfully for user: ${user.uid}');
      } else {
        // Create new CV
        final newCvDoc = await _dbService.createCV(cvData);
        cvId = newCvDoc.id;
        // Update the document with the cvId
        await _dbService.updateCV(
          cvId: cvId,
          data: {'cvId': cvId},
        );
        debugPrint('CV created successfully for user: ${user.uid}');
      }

      // Send notification about CV update and trigger job matching
      try {
        final notificationService = NotificationService();
        await notificationService.sendNotification(
          userId: user.uid,
          type: 'cv_updated',
          title: 'CV Updated Successfully ✅',
          body: existingCV != null && existingCV.exists
              ? 'Your CV has been updated. We\'ll match you with new job opportunities!'
              : 'Your CV is now complete! We\'ll match you with relevant job opportunities.',
          data: {
            'cvId': cvId,
            'isNew': existingCV == null || !existingCV.exists,
          },
        );

        // Trigger job matching for updated CV (fire and forget)
        _triggerJobMatchingAfterCVUpdate(user.uid);
      } catch (e) {
        debugPrint('Error sending CV update notification: $e');
        // Don't block CV save if notification fails
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'CV saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to save CV';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          errorMessage =
              'Permission denied. Please check your account permissions.';
        } else if (errorString.contains('validation') ||
            errorString.contains('invalid')) {
          errorMessage =
              'Invalid CV data. Please check all fields and try again.';
        } else if (errorString.contains('not found')) {
          errorMessage = 'User profile not found. Please try logging in again.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    } finally {
      // Loading complete
    }
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          controller.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
      child: IgnorePointer(
        child: _buildModernTextField(
          controller: controller,
          label: label,
          prefixIcon: Icons.calendar_today,
          validator: (value) => null,
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      scrollPadding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDesignSystem.spaceXL,
      ),
      validator: validator,
      style: AppDesignSystem.bodyLarge(context),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppDesignSystem.bodyMedium(context).copyWith(
          color: AppDesignSystem.onSurfaceVariant(context),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppDesignSystem.primary(context),
        ),
        filled: true,
        fillColor: AppDesignSystem.surfaceContainerHighest(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          borderSide: BorderSide(
            color: AppDesignSystem.outlineVariant(context),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          borderSide: BorderSide(
            color: AppDesignSystem.outlineVariant(context),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          borderSide: BorderSide(
            color: AppDesignSystem.primary(context),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          borderSide: BorderSide(
            color: AppDesignSystem.errorColor(context),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          borderSide: BorderSide(
            color: AppDesignSystem.errorColor(context),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spaceM,
          vertical: AppDesignSystem.spaceM,
        ),
      ),
    );
  }

  String _getEducationTypeLabel(String? type) {
    switch (type) {
      case 'formal':
        return 'Formal Education';
      case 'online':
        return 'Online Course';
      case 'self-taught':
        return 'Self-Taught';
      case 'workshop':
        return 'Workshop';
      case 'certification':
        return 'Certification';
      default:
        return 'Education';
    }
  }

  /// Trigger job matching after CV update (fire and forget)
  Future<void> _triggerJobMatchingAfterCVUpdate(String userId) async {
    try {
      final aiService = GeminiAIService();
      final dbService = FirebaseDatabaseService();
      final notificationService = NotificationService();

      // Get user profile for matching
      final userProfile =
          await ContextService().buildUserProfileContext(userId);
      if (userProfile.isEmpty || userProfile['error'] != null) {
        return; // Can't match without profile
      }

      // Get active jobs
      final jobsSnapshot = await dbService.getActiveJobs(limit: 20);

      for (var jobDoc in jobsSnapshot.docs) {
        final jobData = jobDoc.data() as Map<String, dynamic>? ?? {};
        final jobTitle = (jobData['title'] ?? '').toString();
        final jobDescription =
            (jobData['description'] ?? jobData['desc'] ?? '').toString();

        if (jobTitle.isEmpty || jobDescription.isEmpty) continue;

        try {
          final matchResult = await aiService.matchJobToCandidate(
            jobId: jobDoc.id,                       // NEW: for caching
            candidateId: userId,                    // NEW: for caching
            candidateProfile: userProfile,
            jobRequirements: {
              'title': jobTitle,
              'description': jobDescription,
            },
          );

          final score = matchResult['matchScore'] as int? ?? 0;
          if (score > 70) {
            // Only notify for high matches
            await notificationService.sendNotification(
              userId: userId,
              type: 'job_match',
              title: 'New Job Match! 🎯',
              body:
                  '$jobTitle matches your updated CV ($score% match). Apply now!',
              data: {
                'jobId': jobDoc.id,
                'jobTitle': jobTitle,
                'matchScore': score,
              },
            );
            break; // Only send one notification per CV update
          }
        } catch (e) {
          debugPrint('Error matching job ${jobDoc.id}: $e');
          // Continue with next job
        }
      }
    } catch (e) {
      debugPrint('Error triggering job matching: $e');
      // Fail silently - this is a background process
    }
  }
}
