import 'package:flutter/material.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';

class ApplyJobDialog extends StatefulWidget {
  final String jobTitle;
  final VoidCallback onCancel;
  final Function(String coverLetter, double? bidAmount) onSubmit;

  const ApplyJobDialog({
    super.key,
    required this.jobTitle,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<ApplyJobDialog> createState() => _ApplyJobDialogState();
}

class _ApplyJobDialogState extends State<ApplyJobDialog> {
  final _coverLetterController = TextEditingController();
  final _bidController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Apply for ${widget.jobTitle}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you the best fit?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  hintText: 'Write a short cover letter...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please write a cover letter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Proposed Bid / Salary (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bidController,
                decoration: const InputDecoration(
                  prefixText: 'BWP ',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        StandardButton(
          label: 'Cancel',
          onPressed: widget.onCancel,
          type: StandardButtonType.text,
        ),
        StandardButton(
          label: 'Submit Proposal',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final bid = double.tryParse(_bidController.text);
              widget.onSubmit(_coverLetterController.text, bid);
            }
          },
          type: StandardButtonType.primary,
        ),
      ],
    );
  }
}
