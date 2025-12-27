import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  String? get _uid => _authService.getCurrentUser()?.uid;

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.trainer},
      child: HintsWrapper(
        screenId: 'courses',
        child: Scaffold(
        appBar: AppAppBar(
          title: 'My Courses',
          variant: AppBarVariant.primary, // Blue background with white text
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateCourseDialog,
            ),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Published'),
                      Tab(text: 'Drafts'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CoursesList(
                      query: _queryCourses(status: 'published'),
                      emptyTitle: 'No published courses',
                      emptyMessage:
                          'Create a course and get it approved to reach students.',
                    ),
                    _CoursesList(
                      query: _queryCourses(status: 'pending'),
                      emptyTitle: 'No pending courses',
                      emptyMessage:
                          'Courses awaiting admin approval will appear here.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Query<Map<String, dynamic>> _queryCourses({required String status}) {
    final uid = _uid;
    if (uid == null) {
      return _firestore
          .collection('courses')
          .where('trainerId', isEqualTo: '_');
    }
    // Map 'published' to 'approved' for backward compatibility
    final queryStatus = status == 'published' ? 'approved' : status;
    // Support both trainerId and userId
    return _firestore
        .collection('courses')
        .where('status', isEqualTo: queryStatus)
        .where(Filter.or(
          Filter('trainerId', isEqualTo: uid),
          Filter('userId', isEqualTo: uid),
          Filter('creatorId', isEqualTo: uid),
        ))
        .orderBy('createdAt', descending: true);
  }

  void _showCreateCourseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StandardInput(
                  controller: titleController,
                  label: 'Title',
                  hint: 'e.g. Flutter Fundamentals',
                  prefixIcon: Icons.video_library,
                ),
                AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                StandardInput(
                  controller: descriptionController,
                  label: 'Description',
                  hint: 'What will students learn?',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            StandardButton(
              label: 'Cancel',
              type: StandardButtonType.text,
              onPressed: () => Navigator.pop(context),
            ),
            StandardButton(
              label: 'Create Draft',
              onPressed: () async {
                final uid = _uid;
                if (uid == null) return;
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty) return;

                // Support both trainerId and userId for backward compatibility
                final courseData = {
                  'title': title,
                  'description': description,
                  'status': 'pending', // Requires admin approval
                  'approvalStatus': 'pending',
                  'isApproved': false,
                  'isVerified': false,
                  'enrolledCount': 0,
                  'ratingAvg': 0,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                // Check if user is a trainer, otherwise use userId
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();
                final userData = userDoc.data();
                final isTrainer = userData?['accountType'] == 'trainer' ||
                    userData?['userType'] == 'trainer' ||
                    userData?['isTrainer'] == true;

                if (isTrainer) {
                  courseData['trainerId'] = uid;
                } else {
                  courseData['userId'] = uid;
                  courseData['creatorId'] = uid;
                }

                await _firestore.collection('courses').add(courseData);

                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class _CoursesList extends StatelessWidget {
  final Query<Map<String, dynamic>> query;
  final String emptyTitle;
  final String emptyMessage;

  const _CoursesList({
    required this.query,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingWidget(message: 'Loading courses...'),
          );
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load courses',
            message: snap.error.toString(),
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return EmptyState(
            icon: Icons.video_library_outlined,
            title: emptyTitle,
            message: emptyMessage,
          );
        }

        return ListView.builder(
          padding: AppDesignSystem.paddingM,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final title = (data['title'] ?? '').toString();
            final description = (data['description'] ?? '').toString();
            final students = (data['enrolledCount'] is num)
                ? (data['enrolledCount'] as num).toInt()
                : 0;
            final rating = (data['ratingAvg'] is num)
                ? (data['ratingAvg'] as num).toDouble()
                : 0.0;
            return _CourseCard(
              title: title.isEmpty ? 'Course' : title,
              description: description,
              students: students,
              rating: rating,
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(title.isEmpty ? 'Course' : title),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (description.isNotEmpty) Text(description),
                            AppDesignSystem.verticalSpace(
                                AppDesignSystem.spaceM),
                            Text('Students: $students'),
                            Text(
                              'Rating: ${rating == 0 ? '—' : rating.toStringAsFixed(1)}',
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        StandardButton(
                          label: 'Close',
                          type: StandardButtonType.text,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final int students;
  final double rating;
  final VoidCallback onTap;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.students,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: EdgeInsets.only(bottom: AppDesignSystem.spaceM),
      onTap: onTap,
      padding: AppDesignSystem.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: colorScheme.onSurfaceVariant),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                '$students students',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Icon(Icons.star, size: 16, color: colorScheme.secondary),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                rating == 0 ? '—' : rating.toStringAsFixed(1),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
