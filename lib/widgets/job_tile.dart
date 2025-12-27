import 'package:freelance_app/services/firebase/firebase_auth_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freelance_app/screens/homescreen/components/job_details.dart';
import 'package:freelance_app/utils/global_methods.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/cached_image_widget.dart';

class JobTile extends StatefulWidget {
  final String jobID;
  final String jobTitle;
  final String jobDesc;
  final String uploadedBy;
  final String contactName;
  final String contactImage;
  final String contactEmail;
  final String jobLocation;
  final bool recruiting;
  final VoidCallback? onTap;

  const JobTile({
    super.key,
    required this.jobID,
    required this.jobTitle,
    required this.jobDesc,
    required this.uploadedBy,
    required this.contactName,
    required this.contactImage,
    required this.contactEmail,
    required this.jobLocation,
    required this.recruiting,
    this.onTap,
  });

  @override
  State<JobTile> createState() => _JobTileState();
}

class _JobTileState extends State<JobTile> {
  final _authService = FirebaseAuthService();

  Widget _buildLeading(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final imageUrl = widget.contactImage.trim();

    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.business, color: colorScheme.onSurfaceVariant),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: SizedBox(
        width: 44,
        height: 44,
        child: CachedImageWidget(
          imageUrl: imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.business, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingXS,
        bottom: AppTheme.spacingXS,
        left: 0,
        right: 0,
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: widget.onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailsScreen(
                      id: widget.uploadedBy,
                      jobId: widget.jobID,
                    ),
                  ),
                );
              },
          onLongPress: _deleteDialog,
          contentPadding: const EdgeInsets.all(AppTheme.spacingXS),
          leading: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(width: 1, color: colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.only(right: AppTheme.spacingXS),
            child: _buildLeading(theme),
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXS / 2),
            child: Text(
              widget.jobTitle,
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXS / 2),
                child: Text(
                  widget.contactName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXS / 2),
                child: Text(
                  widget.jobDesc,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDialog() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    final uid = user.uid;
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Delete job?'),
          content: Text(
            'Are you sure you want to delete this job?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            _textButtonCancel(),
            _textButtonDelete(uid),
          ],
        );
      },
    );
  }

  Widget _textButtonDelete(String uid) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: () async {
        try {
          if (widget.uploadedBy == uid) {
            final dbService = FirebaseDatabaseService();
            await dbService.softDeleteJob(widget.jobID);
            if (!mounted) return;
            final navigator = Navigator.of(context);
            if (context.mounted) {
              if (navigator.canPop()) navigator.pop();
              if (navigator.canPop()) navigator.pop();
              await Fluttertoast.showToast(
                msg: 'The job has been successfully deleted',
                toastLength: Toast.LENGTH_LONG,
                backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                fontSize: 14,
              );
            }
          } else {
            final navigator = Navigator.of(context);
            if (context.mounted) {
              if (navigator.canPop()) navigator.pop();
              if (navigator.canPop()) navigator.pop();
              GlobalMethod.showErrorDialog(
                context: context,
                icon: Icons.verified_user_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
                title: 'Unable to delete',
                body: 'Only the user who created the job can delete it',
                buttonText: 'OK',
              );
            }
          }
        } catch (error) {
          if (mounted) {
            GlobalMethod.showErrorDialog(
              context: context,
              icon: Icons.error_rounded,
              iconColor: Theme.of(context).colorScheme.error,
              title: 'Error',
              body: 'Unable to delete job',
              buttonText: 'OK',
            );
          }
        }
      },
      child: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: colorScheme.error,
          ),
          const Text(' Yes'),
        ],
      ),
    );
  }

  Widget _textButtonCancel() {
    return TextButton(
      onPressed: () {
        Navigator.canPop(context) ? Navigator.pop(context) : null;
      },
      child: Row(children: const [
        Icon(
          Icons.close_rounded,
        ),
        Text(
          ' No',
        ),
      ]),
    );
  }
}
