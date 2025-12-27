import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';
import 'package:freelance_app/widgets/common/standard_input.dart';
import 'package:freelance_app/widgets/common/snackbar_helper.dart';
import 'package:freelance_app/services/notifications/notification_service.dart';
import 'package:freelance_app/services/firebase/firebase_database_service.dart';

/// Dialog for posting a new tender
/// Only companies can post tenders
class PostTenderDialog extends StatefulWidget {
  final String organizationId;
  final String organizationName;

  const PostTenderDialog({
    super.key,
    required this.organizationId,
    required this.organizationName,
  });

  @override
  State<PostTenderDialog> createState() => _PostTenderDialogState();
}

class _PostTenderDialogState extends State<PostTenderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _dbService = FirebaseDatabaseService();
  final _notificationService = NotificationService();
  DateTime? _deadline;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Please select a deadline');
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tenderDoc = await _firestore.collection('tenders').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'budget': double.tryParse(_budgetController.text.trim()) ?? 0.0,
        'deadline': Timestamp.fromDate(_deadline!),
        'organization': widget.organizationName,
        'organizationId': widget.organizationId,
        'status': 'Open',
        'approvalStatus': 'pending',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify organization (confirmation)
      try {
        await _notificationService.sendNotification(
          userId: widget.organizationId,
          type: 'tender_posted',
          title: 'Tender Posted Successfully ✅',
          body: 'Your tender "${_titleController.text.trim()}" has been posted and is now visible to bidders.',
          data: {
            'tenderId': tenderDoc.id,
            'tenderTitle': _titleController.text.trim(),
          },
          sendEmail: true,
        );
      } catch (e) {
        debugPrint('Error sending tender confirmation: $e');
      }

      // Notify admins about new tender
      try {
        final admins = await _dbService.searchUsers(limit: 25);
        for (var adminDoc in admins.docs) {
          final adminData = adminDoc.data() as Map<String, dynamic>?;
          if (adminData?['isAdmin'] == true) {
            await _notificationService.sendNotification(
              userId: adminDoc.id,
              type: 'new_tender_posted',
              title: 'New Tender Posted',
              body: '${widget.organizationName} posted a new tender "${_titleController.text.trim()}".',
              data: {
                'tenderId': tenderDoc.id,
                'organizationId': widget.organizationId,
                'tenderTitle': _titleController.text.trim(),
              },
              sendEmail: true,
            );
          }
        }
      } catch (e) {
        debugPrint('Error sending admin notifications: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.showSuccess(context, 'Tender posted successfully!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post New Tender'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StandardInput(
                controller: _titleController,
                label: 'Tender Title *',
                hint: 'e.g. Website Development',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              StandardInput(
                controller: _categoryController,
                label: 'Category *',
                hint: 'e.g. Technology, Construction',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              StandardInput(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe the tender requirements...',
                maxLines: 4,
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              StandardInput(
                controller: _budgetController,
                label: 'Budget (BWP)',
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final budget = double.tryParse(v);
                    if (budget == null || budget < 0) {
                      return 'Invalid budget amount';
                    }
                  }
                  return null;
                },
              ),
              AppDesignSystem.verticalSpace(AppDesignSystem.spaceM),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _deadline = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Deadline *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: _deadline != null
                        ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                        : 'Select',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        StandardButton(
          label: 'Cancel',
          type: StandardButtonType.text,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        StandardButton(
          label: _isSubmitting ? 'Posting...' : 'Post Tender',
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}
