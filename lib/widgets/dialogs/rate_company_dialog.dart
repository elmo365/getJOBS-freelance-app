import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/standard_button.dart';

class RateCompanyDialog extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String jobId;
  final String jobTitle;
  final Function(double rating, String feedback)? onSubmit;

  const RateCompanyDialog({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.jobId,
    required this.jobTitle,
    this.onSubmit,
  });

  @override
  State<RateCompanyDialog> createState() => _RateCompanyDialogState();
}

class _RateCompanyDialogState extends State<RateCompanyDialog> {
  double _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.companyName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'How was your experience working with this company?',
              textAlign: TextAlign.center,
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            RatingBar.builder(
              initialRating: 0,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            AppDesignSystem.verticalSpace(AppDesignSystem.spaceL),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Feedback (Optional)',
                hintText: 'Share details about your experience...',
                border: OutlineInputBorder(),
              ),
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
          label: 'Submit Rating',
          type: StandardButtonType.primary,
          onPressed: () async {
            if (_rating == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a rating')),
              );
              return;
            }

            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            try {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Please log in to rate')),
                  );
                }
                return;
              }

              final db = FirebaseFirestore.instance;
              final ratingId = '${currentUser.uid}_${widget.companyId}_${widget.jobId}';
              final ratingRef = db.collection('ratings').doc(ratingId);
              final userRef = db.collection('users').doc(widget.companyId);

              try {
                await db.runTransaction((transaction) async {
                  final existing = await transaction.get(ratingRef);
                  if (existing.exists) {
                    throw Exception('already_exists');
                  }

                  final userSnap = await transaction.get(userRef);
                  double oldRating = 0.0;
                  int oldCount = 0;
                  if (userSnap.exists) {
                    final data = userSnap.data()!;
                    if (data['rating'] != null) oldRating = (data['rating'] as num).toDouble();
                    if (data['rating_count'] != null) oldCount = data['rating_count'] as int;
                  }

                  final newCount = oldCount + 1;
                  final newAvg = double.parse(((oldRating * oldCount + _rating) / newCount).toStringAsFixed(1));

                  transaction.set(ratingRef, {
                    'raterId': currentUser.uid,
                    'raterType': 'jobSeeker',
                    'ratedUserId': widget.companyId,
                    'ratedUserType': 'company',
                    'jobId': widget.jobId,
                    'jobTitle': widget.jobTitle,
                    'rating': _rating,
                    'feedback': _feedbackController.text.trim(),
                    'isApproved': true,
                    'isFlagged': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (userSnap.exists) {
                    transaction.update(userRef, {
                      'rating': newAvg,
                      'rating_count': newCount,
                    });
                  } else {
                    transaction.set(userRef, {
                      'rating': newAvg,
                      'rating_count': newCount,
                    }, SetOptions(merge: true));
                  }
                });
              } on Exception catch (e) {
                if (e.toString().contains('already_exists')) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('You have already rated this company for this job')),
                    );
                  }
                  return;
                }
                rethrow;
              }

              if (widget.onSubmit != null) {
                widget.onSubmit!(_rating, _feedbackController.text.trim());
              }

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Rating submitted successfully')),
                );
                navigator.pop();
              }
            } catch (e) {
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error saving rating: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
