import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/screens/employers/application_review_screen.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/contact_action_row.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

class Applicant extends StatefulWidget {
  final String applicationId;
  final String name;
  final DateTime date;
  final String profilePic;
  final String jobId;
  final String jobTitle;
  final String? status;
  final String? userId; // Add userId to fetch contact info

  const Applicant({
    super.key,
    required this.applicationId,
    required this.name,
    required this.date,
    required this.profilePic,
    required this.jobId,
    required this.jobTitle,
    this.status,
    this.userId,
  });

  @override
  State<Applicant> createState() => _ApplicantState();
}

class _ApplicantState extends State<Applicant> {
  final _dbService = FirebaseDatabaseService();
  Map<String, dynamic>? _applicantProfile;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _loadApplicantProfile();
    }
  }

  Future<void> _loadApplicantProfile() async {
    if (widget.userId == null) return;
    try {
      final userDoc = await _dbService.getUser(widget.userId!);
      if (userDoc != null && mounted) {
        setState(() {
          _applicantProfile = userDoc.data() as Map<String, dynamic>? ?? {};
        });
      }
    } catch (e) {
      debugPrint('Error loading applicant profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = _applicantProfile?['email'] as String?;
    final phone = _applicantProfile?['phone_number'] as String? ?? _applicantProfile?['phone'] as String?;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (context) => ApplicationReviewScreen(
              applicationId: widget.applicationId,
              jobId: widget.jobId,
              jobTitle: widget.jobTitle,
            ),
          ),
        )
            .then((refreshed) {
          if (refreshed == true) {
            // Refresh parent list if needed
          }
        });
      },
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundImage:
              widget.profilePic.isNotEmpty ? NetworkImage(widget.profilePic) : null,
          child: widget.profilePic.isEmpty
              ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.name,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.status != null) _buildStatusChip(context, widget.status!),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd().add_jm().format(widget.date)),
            Text(
              widget.jobTitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        children: [
          if (email != null || phone != null) ...[
            Padding(
              padding: AppDesignSystem.paddingM,
              child: ContactActionRow(
                email: email,
                phoneNumber: phone,
                compact: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    late final Color color;
    late final String label;

    switch (status) {
      case 'approved':
        color = colorScheme.primary;
        label = 'Approved';
        break;
      case 'rejected':
        color = colorScheme.error;
        label = 'Rejected';
        break;
      case 'interview_scheduled':
        color = colorScheme.tertiary;
        label = 'Interview';
        break;
      default:
        color = colorScheme.outline;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppDesignSystem.borderRadiusCircular,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
