import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/services/job_expiry_service.dart';

/// Dialog for managing job deadline - extend or close
class JobDeadlineManagementDialog extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String companyId;
  final DateTime? currentDeadline;
  final VoidCallback onUpdate;

  const JobDeadlineManagementDialog({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.companyId,
    this.currentDeadline,
    required this.onUpdate,
  });

  @override
  State<JobDeadlineManagementDialog> createState() =>
      _JobDeadlineManagementDialogState();
}

class _JobDeadlineManagementDialogState
    extends State<JobDeadlineManagementDialog> {
  final _expiryService = JobExpiryService();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to 30 days from now
    _selectedDate = DateTime.now().add(const Duration(days: 30));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select New Deadline',
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _extendDeadline() async {
    if (_selectedDate == null) return;

    setState(() => _isLoading = true);

    try {
      await _expiryService.extendJobDeadline(
        jobId: widget.jobId,
        newDeadline: _selectedDate!,
        companyId: widget.companyId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Job deadline extended to ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extend deadline: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _closeJob() async {
    setState(() => _isLoading = true);

    try {
      await _expiryService.closeJob(
        jobId: widget.jobId,
        companyId: widget.companyId,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job closed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to close job: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text('Manage: ${widget.jobTitle}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.currentDeadline != null) ...[
              Container(
                padding: AppDesignSystem.paddingM,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppDesignSystem.borderRadiusM,
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: colorScheme.primary, size: 20),
                    AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Deadline',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            widget.currentDeadline!
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            ],
            Text(
              'Extend Deadline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _selectDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                _selectedDate != null
                    ? _selectedDate!.toLocal().toString().split(' ')[0]
                    : 'Select New Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            const Divider(),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            Text(
              'Or close this job posting',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceS),
            Text(
              'Closing will stop all new applications.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: _isLoading ? null : _closeJob,
          icon: const Icon(Icons.close),
          label: const Text('Close Job'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
          ),
        ),
        FilledButton.icon(
          onPressed:
              (_isLoading || _selectedDate == null) ? null : _extendDeadline,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.update),
          label: const Text('Extend'),
        ),
      ],
    );
  }
}

/// Widget showing job expiry status with action button
class JobExpiryWidget extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final String companyId;
  final DateTime? deadline;
  final VoidCallback onUpdate;

  const JobExpiryWidget({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.companyId,
    this.deadline,
    required this.onUpdate,
  });

  Color _getUrgencyColor(BuildContext context, int daysLeft) {
    if (daysLeft < 0) return Theme.of(context).colorScheme.error;
    if (daysLeft <= 3) return AppDesignSystem.warning;
    if (daysLeft <= 7) return AppDesignSystem.brandYellow;
    return AppDesignSystem.brandGreen;
  }

  IconData _getUrgencyIcon(int daysLeft) {
    if (daysLeft < 0) return Icons.event_busy;
    if (daysLeft <= 3) return Icons.warning_amber;
    if (daysLeft <= 7) return Icons.schedule;
    return Icons.check_circle_outline;
  }

  String _getStatusText(int daysLeft) {
    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Closes today!';
    if (daysLeft == 1) return '1 day left';
    if (daysLeft <= 7) return '$daysLeft days left';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    if (deadline == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final daysLeft = deadline!.difference(now).inDays;
    final color = _getUrgencyColor(context, daysLeft);
    final icon = _getUrgencyIcon(daysLeft);
    final statusText = _getStatusText(daysLeft);

    return Container(
      padding: AppDesignSystem.paddingS,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadiusS,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceXS),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          AppDesignSystem.horizontalSpace(AppDesignSystem.spaceS),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => JobDeadlineManagementDialog(
                  jobId: jobId,
                  jobTitle: jobTitle,
                  companyId: companyId,
                  currentDeadline: deadline,
                  onUpdate: onUpdate,
                ),
              );
            },
            borderRadius: AppDesignSystem.borderRadiusS,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(
                Icons.settings,
                size: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
