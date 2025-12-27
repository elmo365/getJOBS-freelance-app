import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:freelance_app/services/auth/app_user_role.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/app_text_field.dart';
import 'package:freelance_app/widgets/common/role_guard.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/email_service.dart';
import 'package:freelance_app/services/connectivity_service.dart';
import 'package:freelance_app/widgets/common/hints_wrapper.dart';
import 'package:freelance_app/widgets/common/app_app_bar.dart';
import 'package:freelance_app/services/interview_service.dart';
import 'package:freelance_app/models/interview_model.dart';

class InterviewSchedulingScreen extends StatefulWidget {
  final String? candidateId;
  final String? candidateName;
  final String? jobId;
  final String? jobTitle;
  final String? applicationId; // NEW: Link to application

  const InterviewSchedulingScreen({
    super.key,
    this.candidateId,
    this.candidateName,
    this.jobId,
    this.jobTitle,
    this.applicationId, // NEW: optional for backward compatibility
  });

  @override
  State<InterviewSchedulingScreen> createState() =>
      _InterviewSchedulingScreenState();
}

class _InterviewSchedulingScreenState extends State<InterviewSchedulingScreen>
    with ConnectivityAware {
  final _dbService = FirebaseDatabaseService();
  final _authService = FirebaseAuthService();
  final _notificationService = NotificationService();
  final _emailService = EmailService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  String? _selectedInterviewType = 'Virtual';
  String? _selectedMedium = 'video'; // video, phone, chat
  int _interviewDuration = 60; // Default 1 hour
  final _notesController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  String? _conflictMessage; // To show conflict warning

  @override
  void initState() {
    super.initState();
    if (widget.candidateId != null) {
      _selectedDay = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RoleGuard(
      allow: const {AppUserRole.employer},
      child: HintsWrapper(
        screenId: 'interview_scheduling',
        child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppAppBar(
          title: 'Schedule Interview',
          variant: AppBarVariant.primary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Calendar
              AppCard(
                margin: AppDesignSystem.paddingM,
                padding: AppDesignSystem.paddingS,
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 90)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),

              // Interview Details Form
              Padding(
                padding: AppDesignSystem.paddingM,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interview Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    if (widget.jobId == null || widget.candidateId == null) ...[
                      if (widget.jobId == null) ...[
                        AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                        const Text('Job and candidate are pre-selected'),
                      ],
                    ] else ...[
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      AppCard(
                        padding: AppDesignSystem.paddingM,
                        child: Row(
                          children: [
                            Icon(Icons.info, color: colorScheme.primary),
                            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.jobTitle != null)
                                    Text(
                                      'Job: ${widget.jobTitle}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                  if (widget.candidateName != null)
                                    Text(
                                      'Candidate: ${widget.candidateName}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppDesignSystem.onSurfaceVariant(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    
                    // Selected Date Display
                    if (_selectedDay != null)
                      Container(
                        padding: EdgeInsets.all(AppDesignSystem.spaceM),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: colorScheme.primary),
                            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Interview Date',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedDay!.day} ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Select Time *',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select time',
                          style: TextStyle(
                            color: _selectedTime != null
                                ? AppDesignSystem.onSurface(context)
                                : AppDesignSystem.onSurfaceVariant(context),
                          ),
                        ),
                      ),
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedInterviewType,
                      decoration: const InputDecoration(
                        labelText: 'Interview Type *',
                        prefixIcon: Icon(Icons.video_call),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Virtual',
                          child: Text('Virtual (Video/Phone/Chat)'),
                        ),
                        DropdownMenuItem(
                          value: 'In-person',
                          child: Text('In-person'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedInterviewType = value;
                          // Default medium based on type
                          if (value == 'Virtual') {
                            _selectedMedium = 'video';
                          }
                          _conflictMessage = null; // Clear conflict message
                        });
                      },
                    ),
                    // Medium selection (for Virtual interviews)
                    if (_selectedInterviewType == 'Virtual') ...[                      
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      Text(
                        'Interview Medium *',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Video Call'),
                              selected: _selectedMedium == 'video',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedMedium = 'video');
                                }
                              },
                              avatar: const Icon(Icons.videocam),
                            ),
                          ),
                          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Chat'),
                              selected: _selectedMedium == 'chat',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedMedium = 'chat');
                                }
                              },
                              avatar: const Icon(Icons.chat),
                            ),
                          ),
                          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Phone'),
                              selected: _selectedMedium == 'phone',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedMedium = 'phone');
                                }
                              },
                              avatar: const Icon(Icons.phone),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_selectedInterviewType == 'Virtual' && _selectedMedium == 'video')
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    if (_selectedInterviewType == 'Virtual' && _selectedMedium == 'video')
                      AppTextField(
                        controller: _meetingLinkController,
                        label: 'Meeting Link (Zoom/Meet)',
                        prefixIcon: Icons.link,
                      ),
                    if (_selectedInterviewType == 'In-person')
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    if (_selectedInterviewType == 'In-person')
                      AppTextField(
                        controller: _locationController,
                        label: 'Location',
                        prefixIcon: Icons.location_on,
                      ),
                    // Duration selection
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    DropdownButtonFormField<int>(
                      initialValue: _interviewDuration,
                      decoration: const InputDecoration(
                        labelText: 'Interview Duration',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 30,
                          child: Text('30 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 45,
                          child: Text('45 minutes'),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text('1 hour'),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text('1.5 hours'),
                        ),
                        DropdownMenuItem(
                          value: 120,
                          child: Text('2 hours'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _interviewDuration = value;
                            _conflictMessage = null; // Clear conflict message
                          });
                        }
                      },
                    ),
                    // Conflict warning
                    if (_conflictMessage != null) ...[                      
                      AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                      AppCard(
                        variant: SurfaceVariant.elevated,
                        padding: AppDesignSystem.paddingM,
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Schedule Conflict Detected',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  AppDesignSystem.verticalSpace(AppDesignSystem.spaceXS),
                                  Text(
                                    _conflictMessage!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
                    AppTextField(
                      controller: _notesController,
                      label: 'Notes (Optional)',
                      prefixIcon: Icons.note,
                      maxLines: 3,
                    ),
                    AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
                    StandardButton(
                      label: 'Schedule Interview',
                      onPressed: _scheduleInterview,
                      type: StandardButtonType.primary,
                      icon: Icons.calendar_today,
                      isLoading: _isLoading,
                      fullWidth: true,
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

  /// Helper method to convert month number to name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<void> _scheduleInterview() async {
    final candidateId = widget.candidateId;
    final jobId = widget.jobId;
    final applicationId = widget.applicationId; // NEW

    if (_selectedDay == null ||
        _selectedTime == null ||
        candidateId == null ||
        jobId == null) {
      SnackbarHelper.showError(context, 'Please fill all required fields');
      return;
    }

    if (!await checkConnectivity(context,
        message:
            'Cannot schedule interview without internet. Please connect and try again.')) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          SnackbarHelper.showError(
              context, 'Please login to schedule interviews');
        }
        return;
      }

      final scheduledDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Convert to UTC for storage (app uses Botswana time +2)
      final utcDateTime = InterviewService.convertToUtc(scheduledDateTime);

      // Check for conflicts with candidate's other interviews
      try {
        final candidateInterviewsQuery = await FirebaseFirestore.instance
            .collection('interviews')
            .where('candidate_id', isEqualTo: candidateId)
            .where('status', whereIn: ['Scheduled', 'Ongoing']).get();
        
        final interviews = candidateInterviewsQuery.docs
            .map((doc) => InterviewModel.fromMap(
                doc.data(), doc.id))
            .toList();

        final availability = InterviewService.checkAvailability(
          utcDateTime,
          _interviewDuration,
          interviews,
          minimumGapMinutes: 30,
        );

        if (!availability.available) {
          if (mounted) {
            setState(() {
              _conflictMessage = availability.reason;
              _isLoading = false;
            });
            SnackbarHelper.showError(context,
                'Scheduling conflict detected. Please choose another time.');
          }
          return;
        }
      } catch (e) {
        // If conflict check fails, warn but allow scheduling
        debugPrint('Warning: Could not check for conflicts: $e');
      }

      final interviewData = {
        'employer_id': user.uid,  // Match Firestore rules (snake_case)
        'candidate_id': candidateId,  // Match Firestore rules (snake_case)
        'jobId': jobId,
        'application_id': applicationId, // NEW: Link to application
        'jobTitle': widget.jobTitle,
        'candidateName': widget.candidateName,
        'employerName': 'Employer', // Will be updated with actual name
        'scheduled_date': utcDateTime.toIso8601String(),
        'type': _selectedInterviewType,
        'medium': _selectedMedium ?? 'video', // New field
        'duration_minutes': _interviewDuration, // New field
        'timezone': 'Africa/Gaborone', // Botswana timezone
        'location': _selectedInterviewType == 'In-person'
            ? _locationController.text
            : null,
        'meeting_link': _selectedInterviewType == 'Virtual' &&
                _selectedMedium == 'video'
            ? _meetingLinkController.text
            : null,
        'notes': _notesController.text,
        'status': 'Scheduled',
        'has_conflict': false,
        'conflicting_interview_ids': [],
        'created_at': DateTime.now().toIso8601String(),
      };

      final interviewDoc = await _dbService.createInterview(interviewData);
      final interviewId = interviewDoc.id;

      // Update application status to "shortlisted" and link interview
      final applications = await _dbService.getApplicationsByJob(jobId);
      for (var appDoc in applications.docs) {
        final appData = appDoc.data() as Map<String, dynamic>;
        if (appData['userId'] == candidateId) {
          await _dbService.updateApplication(
            applicationId: appDoc.id,
            data: {
              'status': 'shortlisted', // Changed from 'interview_scheduled' to 'shortlisted'
              'interviewId': interviewId,
              'interviewDate': scheduledDateTime.toIso8601String(), // NEW: Store interview date
            },
          );
          break;
        }
      }

      // Get candidate name for notification
      String candidateName = widget.candidateName ?? 'Candidate';
      try {
        final candidateDoc = await _dbService.getUser(candidateId);
        if (candidateDoc != null) {
          final candidateData = candidateDoc.data() as Map<String, dynamic>?;
          final nameFromDoc = candidateData?['name'] as String?;
          if (nameFromDoc != null && nameFromDoc.isNotEmpty) {
            candidateName = nameFromDoc;
          }
        }
      } catch (e) {
        debugPrint('Error getting candidate name: $e');
      }

      // Send notification to candidate (in-app + email)
      final interviewTypeText = _selectedInterviewType == 'Virtual' 
          ? 'Virtual interview' 
          : _selectedInterviewType == 'In-person'
              ? 'In-person interview'
              : 'Interview';
      
      await _notificationService.sendNotification(
        userId: candidateId,
        type: 'interview_scheduled',
        title: 'Interview Scheduled 📅',
        body:
            'A $interviewTypeText has been scheduled for "${widget.jobTitle ?? "the position"}" on ${_formatDateTime(scheduledDateTime)}. ${(_selectedInterviewType == 'Virtual' && _meetingLinkController.text.isNotEmpty) ? 'Meeting link: ${_meetingLinkController.text}' : (_selectedInterviewType == 'In-person' && _locationController.text.isNotEmpty) ? 'Location: ${_locationController.text}' : ''}',
        data: {
          'interviewId': interviewId,
          'jobId': jobId,
          'jobTitle': widget.jobTitle,
          'scheduledDate': scheduledDateTime.toIso8601String(),
          'interviewType': _selectedInterviewType,
          if (_selectedInterviewType == 'Virtual' && _meetingLinkController.text.isNotEmpty)
            'meetingLink': _meetingLinkController.text,
          if (_selectedInterviewType == 'In-person' && _locationController.text.isNotEmpty)
            'location': _locationController.text,
        },
        sendEmail: true,
      );

      // Send confirmation to employer
      try {
        final user = _authService.getCurrentUser();
        if (user != null) {
          await _notificationService.sendNotification(
            userId: user.uid,
            type: 'interview_scheduled_employer',
            title: 'Interview Scheduled ✅',
            body: 'You have scheduled a $interviewTypeText for $candidateName for "${widget.jobTitle ?? 'the position'}" on ${_formatDateTime(scheduledDateTime)}.',
            data: {
              'interviewId': interviewId,
              'jobId': jobId,
              'jobTitle': widget.jobTitle,
              'candidateId': candidateId,
              'candidateName': candidateName,
              'scheduledDate': scheduledDateTime.toIso8601String(),
              'interviewType': _selectedInterviewType,
            },
            sendEmail: true,
          );
        }
      } catch (e) {
        debugPrint('Failed to notify employer of interview: $e');
      }

      // Send Rich Email (legacy emailService - keep for compatibility)
      try {
        final candidateDoc = await _dbService.getUser(candidateId);
        final candidateEmail = candidateDoc?.data() != null ? (candidateDoc!.data() as Map<String, dynamic>)['email'] as String? : null;

        if (candidateEmail != null) {
          await _emailService.sendInterviewInviteEmail(
            toEmail: candidateEmail, 
            candidateName: candidateName,
            employerName: 'The Employer',
            jobTitle: widget.jobTitle ?? 'Position',
            interviewDate: '${scheduledDateTime.day}/${scheduledDateTime.month}/${scheduledDateTime.year}',
            interviewTime: '${scheduledDateTime.hour}:${scheduledDateTime.minute.toString().padLeft(2, '0')}',
            interviewType: _selectedInterviewType!,
            location: _locationController.text.isNotEmpty ? _locationController.text : null,
            meetingLink: _meetingLinkController.text.isNotEmpty ? _meetingLinkController.text : null,
          );
        }
      } catch (e) {
        debugPrint('Legacy email send skipped or failed: $e');
      }

      // Schedule interview reminder (24 hours before)
      try {
        final reminderDate = scheduledDateTime.subtract(const Duration(hours: 24));
        if (reminderDate.isAfter(DateTime.now())) {
          // Schedule reminder notification (this would ideally be done via Cloud Functions)
          // For now, we'll store it in Firestore and a scheduled job can pick it up
          await FirebaseFirestore.instance.collection('scheduled_notifications').add({
            'userId': candidateId,
            'type': 'interview_reminder',
            'title': 'Interview Reminder 📅',
            'body': 'Reminder: You have an interview for "${widget.jobTitle ?? "the position"}" tomorrow at ${_formatDateTime(scheduledDateTime)}.',
            'scheduledFor': reminderDate.toIso8601String(),
            'data': {
              'interviewId': interviewId,
              'jobId': jobId,
              'jobTitle': widget.jobTitle,
              'scheduledDate': scheduledDateTime.toIso8601String(),
            },
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('Error scheduling interview reminder: $e');
        // Don't block interview scheduling if reminder fails
      }

      // Send confirmation to employer
      try {
        final user = _authService.getCurrentUser();
        if (user != null) {
          await _notificationService.sendNotification(
            userId: user.uid,
            type: 'interview_scheduled',
            title: 'Interview Scheduled Successfully ✅',
            body: 'You have scheduled a $interviewTypeText with $candidateName for "${widget.jobTitle ?? "the position"}" on ${_formatDateTime(scheduledDateTime)}.',
            data: {
              'interviewId': interviewId,
              'jobId': jobId,
              'candidateId': candidateId,
              'scheduledDate': scheduledDateTime.toIso8601String(),
            },
            sendEmail: false, // Don't email employer for their own actions
          );
        }
      } catch (e) {
        debugPrint('Error sending employer confirmation: $e');
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
            context, 'Interview scheduled successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to schedule interview';
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (errorString.contains('permission') ||
            errorString.contains('forbidden')) {
          errorMessage =
              'Permission denied. You may not have access to schedule interviews.';
        } else if (errorString.contains('not found')) {
          errorMessage =
              'Candidate or job not found. Please refresh and try again.';
        } else if (errorString.contains('notification')) {
          errorMessage =
              'Interview scheduled but failed to send notification. The candidate may not receive an email.';
        }

        SnackbarHelper.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
