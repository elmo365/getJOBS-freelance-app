import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:freelance_app/utils/global_variables.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/widgets/job_tile.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';

class Postedjob extends StatefulWidget {
  const Postedjob({super.key});

  @override
  State<Postedjob> createState() => _PostedjobState();
}

class _PostedjobState extends State<Postedjob> {
  String? jobCategoryFilter;

  void getMyData() async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      name = userDoc.get('name');
      userImage = userDoc.get('userImage') ?? userDoc.get('user_image') ?? '';
      address = userDoc.get('address');
    });
  }

  @override
  void initState() {
    super.initState();
    getMyData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'active');
    if (jobCategoryFilter != null) {
      query = query.where('category', isEqualTo: jobCategoryFilter);
    }
    query = query.orderBy('createdAt', descending: true);

    return Expanded(
        child: Column(
      children: [
        Expanded(
          flex: 0,
          child: Row(
            children: [
              const SizedBox(width: AppTheme.spacingS),
              IconButton(
                onPressed: () {
                  showJobCategoriesDialog();
                },
                icon: Icon(
                  Icons.filter_list,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              Text(
                "Filter Jobs based on your choice",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              jobCategoryFilter ?? 'Recent Jobs',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (
              context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
            ) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.data?.docs.isNotEmpty == true) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 0,
                      bottom: AppTheme.spacingM,
                      left: AppTheme.spacingM,
                      right: AppTheme.spacingM,
                    ),
                    child: ListView.builder(
                        itemCount: snapshot.data?.docs.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          final job = snapshot.data!.docs[index].data();
                          return JobTile(
                            jobID: (job['job_id'] as String?) ??
                                (snapshot.data!.docs[index].id),
                            jobTitle: job['title'] as String? ?? '',
                            jobDesc: (job['desc'] as String?) ??
                                (job['description'] as String?) ??
                                '',
                            uploadedBy: (job['userId'] as String?) ??
                                (job['id'] as String?) ??
                                '',
                            contactName: (job['employerName'] as String?) ??
                                (job['name'] as String?) ??
                                '',
                            contactImage: (job['user_image'] as String?) ??
                                (job['userImage'] as String?) ??
                                '',
                            contactEmail: job['email'] as String? ?? '',
                            jobLocation: (job['location'] as String?) ??
                                (job['address'] as String?) ??
                                '',
                            recruiting: job['recruiting'] as bool? ?? true,
                          );
                        }),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXXL),
                    child: Center(
                      child: Image.asset('assets/images/empty.png'),
                    ),
                  );
                }
              } else {
                return EmptyState(
                  icon: Icons.error_outline,
                  title: 'Unable to load jobs',
                  message: 'Please check your connection and try again.',
                );
              }
            },
          ),
        ),
      ],
    ));
  }

  //job filtering

  Future<void> showJobCategoriesDialog() async {
    final size = MediaQuery.of(context).size;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingS,
              bottom: AppTheme.spacingS,
            ),
            child: Text(
              'Job Categories',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          content: SizedBox(
            width: size.width * 0.9,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: jobCategories.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final category = jobCategories[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.business,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  title: Text(category),
                  onTap: () {
                    setState(() {
                      jobCategoryFilter = category;
                    });
                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  jobCategoryFilter = null;
                });
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filter'),
            ),
            TextButton.icon(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
