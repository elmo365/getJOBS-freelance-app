import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/common_widgets.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';

class LiveSessionsScreen extends StatefulWidget {
  const LiveSessionsScreen({super.key});

  @override
  State<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends State<LiveSessionsScreen> {
  final _authService = FirebaseAuthService();
  final _firestore = FirebaseFirestore.instance;

  String? get _uid => _authService.getCurrentUser()?.uid;

  Query<Map<String, dynamic>> _sessionsQuery() {
    final uid = _uid;
    if (uid == null) {
      return _firestore
          .collection('live_sessions')
          .where('trainerId', isEqualTo: '_')
          .orderBy('startsAt', descending: false);
    }
    return _firestore
        .collection('live_sessions')
        .where('trainerId', isEqualTo: uid)
        .orderBy('startsAt', descending: false);
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allow: const {AppUserRole.trainer},
      child: HintsWrapper(
        screenId: 'live_sessions',
        child: Scaffold(
        appBar: AppAppBar(
          title: 'Live Sessions',
          variant: AppBarVariant.primary, // Blue background with white text
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreateSessionDialog,
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sessionsQuery().snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingWidget(message: 'Loading sessions...'),
              );
            }
            if (snap.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load sessions',
                message: snap.error.toString(),
              );
            }

            final nowUtc = DateTime.now().toUtc();
            final allDocs = snap.data?.docs ?? const [];

            final upcoming = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final liveNow = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final past = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            for (final doc in allDocs) {
              final data = doc.data();
              final status = (data['status'] ?? '').toString();

              final startsAt = (data['startsAt'] is Timestamp)
                  ? (data['startsAt'] as Timestamp).toDate().toUtc()
                  : null;
              if (startsAt == null) {
                past.add(doc);
                continue;
              }

              final durationMinutes = (data['durationMinutes'] is num)
                  ? (data['durationMinutes'] as num).toInt()
                  : 0;

              final endsAt = (data['endsAt'] is Timestamp)
                  ? (data['endsAt'] as Timestamp).toDate().toUtc()
                  : startsAt.add(
                      Duration(
                          minutes: durationMinutes <= 0 ? 60 : durationMinutes),
                    );

              final isLiveWindow =
                  startsAt.isBefore(nowUtc) && endsAt.isAfter(nowUtc);

              if (status == 'completed') {
                past.add(doc);
              } else if (isLiveWindow) {
                liveNow.add(doc);
              } else if (endsAt.isBefore(nowUtc) ||
                  endsAt.isAtSameMomentAs(nowUtc)) {
                past.add(doc);
              } else {
                upcoming.add(doc);
              }
            }

            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Live Now'),
                      Tab(text: 'Past'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _LiveSessionsListFromDocs(
                          docs: upcoming,
                          emptyTitle: 'No upcoming sessions',
                          emptyMessage:
                              'Schedule a session to go live with students.',
                          forceStatus: 'scheduled',
                        ),
                        _LiveSessionsListFromDocs(
                          docs: liveNow,
                          emptyTitle: 'No live sessions',
                          emptyMessage:
                              'A session is live when its start time has passed and it hasn\'t ended yet.',
                          forceStatus: 'live',
                        ),
                        _LiveSessionsListFromDocs(
                          docs: past,
                          emptyTitle: 'No past sessions',
                          emptyMessage: 'Completed sessions will appear here.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  void _showCreateSessionDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    DateTime startsAt = DateTime.now().add(const Duration(hours: 1));

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Live Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardInput(
                      controller: titleController,
                      label: 'Title',
                      hint: 'e.g. Portfolio review',
                      prefixIcon: Icons.live_tv,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    StandardInput(
                      controller: durationController,
                      label: 'Duration (minutes)',
                      hint: '60',
                      prefixIcon: Icons.timer,
                      keyboardType: TextInputType.number,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    AppCard(
                      padding: AppDesignSystem.paddingM,
                      child: Row(
                        children: [
                          const Icon(Icons.event),
                          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                          Expanded(
                            child: Text(
                              '${startsAt.toLocal()}'.split('.').first,
                            ),
                          ),
                          StandardButton(
                            label: 'Pick',
                            type: StandardButtonType.text,
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDate: startsAt,
                              );
                              if (date == null) return;
                              if (!context.mounted) return;

                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(startsAt),
                              );
                              if (time == null) return;

                              setState(() {
                                startsAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            },
                          ),
                        ],
                      ),
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
                  label: 'Schedule',
                  onPressed: () async {
                    final uid = _uid;
                    if (uid == null) return;

                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final durationMinutes =
                        int.tryParse(durationController.text.trim()) ?? 60;

                    final duration = Duration(
                        minutes: durationMinutes <= 0 ? 60 : durationMinutes);
                    final endsAt = startsAt.toUtc().add(duration);

                    await _firestore.collection('live_sessions').add({
                      'trainerId': uid,
                      'title': title,
                      'status': 'scheduled',
                      'startsAt': Timestamp.fromDate(startsAt.toUtc()),
                      'endsAt': Timestamp.fromDate(endsAt),
                      'durationMinutes': durationMinutes,
                      'attendeeCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _LiveSessionsListFromDocs extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String emptyTitle;
  final String emptyMessage;
  final String? forceStatus;

  const _LiveSessionsListFromDocs({
    required this.docs,
    required this.emptyTitle,
    required this.emptyMessage,
    this.forceStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return EmptyState(
        icon: Icons.live_tv,
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

        final attendeeCount = (data['attendeeCount'] is num)
            ? (data['attendeeCount'] as num).toInt()
            : 0;
        final durationMinutes = (data['durationMinutes'] is num)
            ? (data['durationMinutes'] as num).toInt()
            : 0;

        final startsAt = (data['startsAt'] is Timestamp)
            ? (data['startsAt'] as Timestamp).toDate().toLocal()
            : null;

        final status = forceStatus ?? (data['status'] ?? '').toString();

        return _SessionCard(
          title: title.isEmpty ? 'Live session' : title,
          date: startsAt == null
              ? 'TBD'
              : '${startsAt.toLocal()}'.split('.').first,
          duration: durationMinutes <= 0 ? '—' : '$durationMinutes min',
          attendees: attendeeCount,
          status: status.isEmpty ? 'scheduled' : status,
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(title.isEmpty ? 'Live session' : title),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            'Status: ${status.isEmpty ? 'scheduled' : status}'),
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                        Text(
                            'Date: ${startsAt == null ? 'TBD' : '${startsAt.toLocal()}'.split('.').first}'),
                        Text(
                            'Duration: ${durationMinutes <= 0 ? '—' : '$durationMinutes min'}'),
                        Text('Attendees: $attendeeCount'),
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
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String date;
  final String duration;
  final int attendees;
  final String status;
  final VoidCallback onTap;

  const _SessionCard({
    required this.title,
    required this.date,
    required this.duration,
    required this.attendees,
    required this.status,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Row(
            children: [
              Icon(
                Icons.event,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Expanded(
                child: Text(
                  date,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
          Row(
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                duration,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
              Icon(
                Icons.people,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
              Text(
                '$attendees',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: AppDesignSystem.paddingSymmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppDesignSystem.borderRadiusCircular,
                ),
                child: Text(
                  status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
