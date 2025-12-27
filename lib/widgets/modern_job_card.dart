import 'package:flutter/material.dart';
import 'package:freelance_app/models/job_model.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/widgets/common/app_card.dart';
import 'package:freelance_app/widgets/common/micro_interactions.dart';
import 'package:freelance_app/widgets/cached_image_widget.dart';

/// Modern Job Card for 2025 UI Standards
/// Features enhanced visual hierarchy, micro-interactions, and modern card design
class ModernJobCard extends StatelessWidget {
  final JobModel job;
  final String? contactEmail;
  final String? contactImage;
  final String? contactName;
  final bool isBookmarked;
  final bool isApplied;
  final int? matchScore;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final VoidCallback? onApply;
  final bool compact;
  final bool showHero;
  final BorderRadius? borderRadius;

  const ModernJobCard({
    super.key,
    required this.job,
    this.contactEmail,
    this.contactImage,
    this.contactName,
    this.isBookmarked = false,
    this.isApplied = false,
    this.matchScore,
    this.onTap,
    this.onBookmark,
    this.onApply,
    this.compact = false,
    this.showHero = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = showHero ? 'job-${job.jobId}' : null;

    Widget card = ContentCard(
      media: _buildCompanyHeader(context),
      title: job.title,
      subtitle: contactName ?? 'Company',
      description: _buildDescription(context),
      actions: _buildActions(context),
      onTap: onTap,
      compact: compact,
      borderRadius: borderRadius,
    );

    if (heroTag != null) {
      card = MicroInteractions.heroWrapper(
        tag: heroTag,
        child: card,
      );
    }

    return Stack(
      children: [
        card,
        if (matchScore != null) _buildMatchScoreBadge(context),
        if (isApplied) _buildAppliedBadge(context),
        if (job.positionsAvailable > 1 || job.positionsFilled > 0)
          _buildPositionBadge(context),
      ],
    );
  }

  Widget _buildCompanyHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: compact ? 80 : 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Company Avatar
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: contactImage?.isNotEmpty == true
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusS),
                      child: CachedImageWidget(
                        imageUrl: contactImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        borderRadius: AppDesignSystem.radiusS,
                        errorWidget: _buildCompanyIcon(colorScheme),
                      ),
                    )
                  : _buildCompanyIcon(colorScheme),
            ),

            const SizedBox(width: 12),

            // Company Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    contactName ?? 'Company',
                    style: (compact
                            ? AppDesignSystem.bodySmall(context)
                            : AppDesignSystem.bodyMedium(context))
                        .copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.location ?? 'Remote',
                            style: AppDesignSystem.bodySmall(context).copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Bookmark Button
            if (onBookmark != null)
              Semantics(
                label: isBookmarked ? 'Remove bookmark' : 'Bookmark job',
                button: true,
                child: IconButton(
                  onPressed: onBookmark,
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark job',
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  iconSize: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyIcon(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.business,
        color: colorScheme.primary,
        size: 20,
      ),
    );
  }

  String _buildDescription(BuildContext context) {
    final parts = <String>[];

    final jobType = job.jobType;
    if (jobType != null && jobType.isNotEmpty) {
      parts.add(jobType);
    }

    if (job.category.isNotEmpty) {
      parts.add(job.category);
    }

    // Add closing date if available
    if (job.deadlineDate != null) {
      final now = DateTime.now();
      final deadline = job.deadlineDate!;
      final daysLeft = deadline.difference(now).inDays;

      if (daysLeft >= 0) {
        final closingText = daysLeft == 0
            ? 'Closes today'
            : daysLeft == 1
                ? 'Closes tomorrow'
                : 'Closes in $daysLeft days';
        parts.add(closingText);
      } else {
        parts.add('Applications closed');
      }
    }

    final typeInfo = parts.join(' • ');

    final description = job.description;
    final truncatedDesc = description.length > 120
        ? '${description.substring(0, 120)}...'
        : description;

    return parts.isNotEmpty ? '$typeInfo\n\n$truncatedDesc' : truncatedDesc;
  }

  List<Widget> _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];

    // Apply Button
    if (onApply != null && !isApplied) {
      actions.add(
        FilledButton.icon(
          onPressed: onApply,
          icon: const Icon(Icons.send, size: 16),
          label: const Text('Apply'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: AppDesignSystem.labelLarge(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Salary Info
    if (job.salary != null && job.salary!.isNotEmpty) {
      actions.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
          ),
          child: Text(
            job.salary!,
            style: AppDesignSystem.labelMedium(context).copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return actions;
  }

  Widget _buildMatchScoreBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.tertiary,
              colorScheme.tertiary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          boxShadow: AppDesignSystem.mediumShadow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: colorScheme.onTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              '$matchScore%',
              style: AppDesignSystem.labelSmall(context).copyWith(
                color: colorScheme.onTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          boxShadow: AppDesignSystem.mediumShadow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              'Applied',
              style: AppDesignSystem.labelSmall(context).copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionBadge(BuildContext context) {
    final isFilled = job.completedAt != null || 
                     job.positionsFilled >= job.positionsAvailable;
    final hasMultiplePositions = job.positionsAvailable > 1;

    // Position badge - show on bottom right if no match score, or adjust position
    final topPosition = matchScore != null ? 50.0 : 12.0;
    final rightPosition = 12.0;

    return Positioned(
      top: topPosition,
      right: rightPosition,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isFilled
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
          border: Border.all(
            color: isFilled
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.blue.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: AppDesignSystem.mediumShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFilled ? Icons.check_circle : Icons.people_outline,
              size: 16,
              color: isFilled ? Colors.green : Colors.blue,
            ),
            const SizedBox(width: 6),
            Text(
              isFilled
                  ? 'Filled'
                  : hasMultiplePositions
                      ? '${job.positionsFilled}/${job.positionsAvailable}'
                      : '${job.positionsFilled}/${job.positionsAvailable}',
              style: AppDesignSystem.labelSmall(context).copyWith(
                color: isFilled ? Colors.green : Colors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Job Card for lists and grids
class CompactJobCard extends StatelessWidget {
  final JobModel job;
  final String? companyName;
  final String? companyImage;
  final VoidCallback? onTap;
  final bool showHero;

  const CompactJobCard({
    super.key,
    required this.job,
    this.companyName,
    this.companyImage,
    this.onTap,
    this.showHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final heroTag = showHero ? 'job-compact-${job.jobId}' : null;

    Widget card = AppCard(
      variant: SurfaceVariant.standard,
      onTap: onTap,
      interactive: onTap != null,
      child: Row(
        children: [
          // Company Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: companyImage?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusS),
                    child: CachedImageWidget(
                      imageUrl: companyImage!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      borderRadius: AppDesignSystem.radiusS,
                      errorWidget: Container(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.business,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.business,
                      color: colorScheme.primary,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // Job Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: AppDesignSystem.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  companyName ?? 'Company',
                  style: AppDesignSystem.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        job.location ?? 'Remote',
                        style: AppDesignSystem.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );

    if (heroTag != null) {
      card = MicroInteractions.heroWrapper(
        tag: heroTag,
        child: card,
      );
    }

    return card;
  }
}
