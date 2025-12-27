import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelance_app/services/validation/input_validators.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/global_methods.dart';
import 'package:freelance_app/utils/global_variables.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:uuid/uuid.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class Upload extends StatefulWidget {
  final String userID;

  const Upload({super.key, required this.userID});
  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final _uploadJobFormKey = GlobalKey<FormState>();

  final TextEditingController _jobCategoryController = TextEditingController();
  final FocusNode _jobCategoryFocusNode = FocusNode();

  final TextEditingController _jobTitleController = TextEditingController();
  final FocusNode _jobTitleFocusNode = FocusNode();

  final TextEditingController _jobDescController = TextEditingController();
  final FocusNode _jobDescFocusNode = FocusNode();

  final TextEditingController _jobDeadlineController = TextEditingController();
  final FocusNode _jobDeadlineFocusNode = FocusNode();

  final TextEditingController _positionsController = TextEditingController();
  final FocusNode _positionsFocusNode = FocusNode();
  
  DateTime? selectedDeadline;
  Timestamp? deadlineDateTimeStamp;

  bool _isLoading = false;

  @override
  void dispose() {
    _jobCategoryController.dispose();
    _jobCategoryFocusNode.dispose();
    _jobTitleController.dispose();
    _jobTitleFocusNode.dispose();
    _jobDescController.dispose();
    _jobDescFocusNode.dispose();
    _jobDeadlineController.dispose();
    _jobDeadlineFocusNode.dispose();
    _positionsController.dispose();
    _positionsFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppAppBar(
          title: 'Post a Job',
          variant: AppBarVariant.primary,
          centerTitle: true,
        ),
        body: Padding(
          padding: AppDesignSystem.paddingFromLTRB(
            AppDesignSystem.spaceM,
            AppDesignSystem.spaceL,
            AppDesignSystem.spaceM,
            AppDesignSystem.spaceM,
          ),
          child: SingleChildScrollView(
            child: AppCard(
              padding: AppDesignSystem.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Job Details',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                  // Required field note
                  Padding(
                    padding: AppDesignSystem.paddingHorizontal(AppDesignSystem.spaceXS),
                    child: Text(
                      '* Required fields',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                  Form(
                    key: _uploadJobFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        Text(
                          'Basic Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _jobCategoryFormField(),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _jobTitleFormField(),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceXL),
                        // Job Details Section
                        Text(
                          'Job Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _jobDescFormField(),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _positionsFormField(),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        _jobDeadlineFormField(),
                      ],
                    ),
                  ),
                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                  StandardButton(
                    label: 'Upload Job',
                    icon: Icons.upload_file,
                    type: StandardButtonType.primary,
                    fullWidth: true,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _uploadJob,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobCategoryFormField() {
    return StandardInput(
      controller: _jobCategoryController,
      focusNode: _jobCategoryFocusNode,
      label: 'Job category *',
      hint: 'Select job category',
      prefixIcon: Icons.category_outlined,
      suffixIcon: const Icon(Icons.expand_more_rounded),
      readOnly: true,
      onTap: _showJobCategoriesDialog,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Job category is required';
        return null;
      },
    );
  }

  Widget _jobTitleFormField() {
    return StandardInput(
      controller: _jobTitleController,
      focusNode: _jobTitleFocusNode,
      label: 'Title *',
      hint: 'e.g. Senior Flutter Developer',
      prefixIcon: Icons.title,
      maxLength: 100,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Job title is required';
        return null;
      },
    );
  }

  Widget _jobDescFormField() {
    return StandardInput(
      controller: _jobDescController,
      focusNode: _jobDescFocusNode,
      label: 'Description *',
      hint: 'Describe the role, responsibilities, and requirements',
      prefixIcon: Icons.description_outlined,
      maxLines: 4,
      maxLength: 300,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Job description is required';
        return null;
      },
    );
  }

  Widget _jobDeadlineFormField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return StandardInput(
      controller: _jobDeadlineController,
      focusNode: _jobDeadlineFocusNode,
      label: 'Deadline *',
      hint: 'Tap to select deadline date (DD/MM/YYYY)',
      prefixIcon: Icons.calendar_today_rounded,
      suffixIcon: Icon(
        Icons.calendar_month_rounded,
        color: colorScheme.primary,
      ),
      readOnly: true,
      onTap: _selectDeadlineDialog,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Deadline date is required';
        return null;
      },
    );
  }

  Widget _positionsFormField() {
    return StandardInput(
      controller: _positionsController,
      focusNode: _positionsFocusNode,
      label: 'Number of Positions *',
      hint: 'e.g. 5 (number of open positions)',
      prefixIcon: Icons.people_outline_rounded,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      maxLength: 3,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Number of positions is required';
        final num = int.tryParse(value);
        if (num == null || num < 1) return 'Must be at least 1';
        return null;
      },
    );
  }

  void _showJobCategoriesDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Job Categories'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: jobCategories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.business,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(jobCategories[index]),
                  onTap: () {
                    setState(() =>
                        _jobCategoryController.text = jobCategories[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _jobCategoryController.text = '');
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectDeadlineDialog() async {
    // Force minimum date to tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    selectedDeadline = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(2100),
    );
    if (selectedDeadline != null) {
      final validationError = InputValidators.validateJobDeadline(selectedDeadline);
      if (validationError != null) {
        if (mounted) {
          GlobalMethodTwo.showErrorDialog(
            error: validationError,
            ctx: context,
          );
        }
        _jobDeadlineController.text = '';
        deadlineDateTimeStamp = null;
        return;
      }
      setState(
        () {
          // Format as DD/MM/YYYY for better readability
          final day = selectedDeadline!.day.toString().padLeft(2, '0');
          final month = selectedDeadline!.month.toString().padLeft(2, '0');
          final year = selectedDeadline!.year;
          _jobDeadlineController.text = '$day/$month/$year';
          deadlineDateTimeStamp = Timestamp.fromMicrosecondsSinceEpoch(
              selectedDeadline!.microsecondsSinceEpoch);
        },
      );
    } else {
      _jobDeadlineController.text = '';
      deadlineDateTimeStamp = null;
    }
  }

  void _uploadJob() async {
    getUserData();
    // Validate before any async work to avoid using context across async gaps.
    if (_jobCategoryController.text == '' ||
        _jobTitleController.text == '' ||
        _jobDescController.text == '' ||
        _jobDeadlineController.text == '') {
      final colorScheme = Theme.of(context).colorScheme;
      GlobalMethod.showErrorDialog(
        context: context,
        icon: Icons.error,
        iconColor: colorScheme.error,
        title: 'Missing Information',
        body: 'Please enter all information about job.',
        buttonText: 'OK',
      );
      return;
    }

    final jobID = const Uuid().v4();
    User? user = FirebaseAuth.instance.currentUser;
    final uid = user!.uid;
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userID)
        .get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    //final isValid = _uploadJobFormKey.currentState!.validate();

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    setState(() {
      _isLoading = true;
      userImage = (userData['user_image'] as String?) ??
          (userData['userImage'] as String?) ??
          userImage;
    });
    try {
      final employerName =
          ((userData['company_name'] as String?)?.trim().isNotEmpty == true)
              ? (userData['company_name'] as String).trim()
              : (userData['name'] as String?)?.trim() ?? name;
      final employerImage = (userData['user_image'] as String?) ??
          (userData['userImage'] as String?) ??
          userImage;
      final employerEmail = (userData['email'] as String?) ?? user.email ?? '';
      final employerLocation = (userData['address'] as String?) ??
          (userData['location'] as String?) ??
          address;

      await FirebaseFirestore.instance.collection('jobs').doc(jobID).set({
        'job_id': jobID,
        'created': Timestamp.now(),
        'createdAt': DateTime.now().toIso8601String(),
        'userId': uid,
        // Backwards/forwards compatibility across screens.
        'id': uid,
        'name': employerName,
        'employerName': employerName,
        'user_image': employerImage,
        'email': employerEmail,
        'location': employerLocation,
        'address': employerLocation,
        'category': _jobCategoryController.text,
        'jobCategory': _jobCategoryController.text,
        'title': _jobTitleController.text,
        'description': _jobDescController.text,
        'desc': _jobDescController.text,
        'deadlineDate': selectedDeadline?.toIso8601String(),
        'deadline_date': _jobDeadlineController.text,
        'deadline_timestamp': deadlineDateTimeStamp,
        'positionsAvailable': int.tryParse(_positionsController.text) ?? 1,
        'positions': int.tryParse(_positionsController.text) ?? 1,
        'positionsFilled': 0,
        'status': 'pending',
        'isVerified': false,
        'isApproved': false,
        'approvalStatus': 'pending',
        'recruiting': true,
        'applicants': 0,
        'comments': [],
        'applicantsList': [],
      });
      await Fluttertoast.showToast(
        msg: 'The job has been successfully uploaded.',
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() {
        _jobCategoryController.clear();
        _jobTitleController.clear();
        _jobDescController.clear();
        _jobDeadlineController.clear();
        _positionsController.clear();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      GlobalMethod.showErrorDialog(
          context: context,
          icon: Icons.error,
          iconColor: Theme.of(context).colorScheme.error,
          title: 'Error',
          body: error.toString(),
          buttonText: 'OK');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void getUserData() async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    setState(() {
      id = userDoc.get('id');
      name = userDoc.get('name');
      userImage = userDoc.get('user_image');
      address = userDoc.get('address');
    });
  }
}

class Persistent {
  static List<String> jobsList = [
    'Mobile developer',
    'Game Developer',
    'Web designer',
    'HR Manager',
    'Manager',
    'Team Leader',
    'Designer',
    'Full stack developer',
    'Marketing',
    'Digital marketing',
  ];

  static List<String> jobCategoryList = [
    'Architecture and Construction',
    'Education and Training',
    'Development - Programming',
    'Business',
    'Information Technology',
    'Human resources',
    'Marketing',
    'Design',
    'Accounting',
  ];
}
