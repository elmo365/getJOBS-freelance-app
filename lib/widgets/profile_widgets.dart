import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_theme.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:freelance_app/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable profile widgets for consistent design across the app

/// Profile header with gradient background and avatar
class ProfileHeader extends StatelessWidget {
  final String? imageUrl;
  final IconData defaultIcon;
  final String title;
  final Widget? badge;
  final String? subtitle;
  final String joinedDate;

  const ProfileHeader({
    super.key,
    this.imageUrl,
    required this.defaultIcon,
    required this.title,
    this.badge,
    this.subtitle,
    required this.joinedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 4,
                color: colorScheme.surface,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.6),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundColor: colorScheme.primary,
              backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                  ? NetworkImage(imageUrl!)
                  : null,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Icon(
                      defaultIcon,
                      size: 60,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          // Title (Name/Company Name)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (badge != null) ...[
            const SizedBox(height: 8),
            badge!,
          ],
          const SizedBox(height: 8),
          // Joined Date
          if (joinedDate.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Joined $joinedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Info card with icon, label, and value
class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLink;
  final VoidCallback? onTap;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      child: Container(
        padding: AppDesignSystem.paddingM,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: AppDesignSystem.paddingS,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppDesignSystem.spaceL,
              ),
            ),
            AppDesignSystem.horizontalSpace(AppDesignSystem.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppDesignSystem.bodySmall(context).copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  AppDesignSystem.verticalSpace(4),
                  Text(
                    value.isEmpty ? 'Not provided' : value,
                    style: AppDesignSystem.bodyMedium(context).copyWith(
                      color: isLink ? colorScheme.primary : colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isLink && value.isNotEmpty)
              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Circular contact button with label
class ProfileContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ProfileContactButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconBrightness = ThemeData.estimateBrightnessForColor(color);
    final iconColor = iconBrightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Section header text
class ProfileSectionHeader extends StatelessWidget {
  final String title;

  const ProfileSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
    );
  }
}

/// Approval status badge for companies
class ApprovalStatusBadge extends StatelessWidget {
  final String status;

  const ApprovalStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    Color badgeColor;
    IconData icon;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = colorScheme.tertiary;
        icon = Icons.verified_rounded;
        text = 'Verified Company';
        break;
      case 'pending':
        badgeColor = colorScheme.secondary;
        icon = Icons.pending_rounded;
        text = 'Pending Approval';
        break;
      case 'rejected':
        badgeColor = colorScheme.error;
        icon = Icons.cancel_rounded;
        text = 'Not Approved';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Role badge (Job Seeker, Employer, etc.)
class RoleBadge extends StatelessWidget {
  final String role;
  final Color? color;

  const RoleBadge({
    super.key,
    required this.role,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 13,
          color: effectiveColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Logout confirmation dialog
class ProfileLogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const ProfileLogoutDialog({
    super.key,
    required this.onConfirm,
  });

  static Future<void> show(BuildContext context, VoidCallback onConfirm) {
    return showDialog(
      context: context,
      builder: (context) => ProfileLogoutDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusM),
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

/// Profile utilities class for common functions
class ProfileUtils {
  /// Launch website URL
  static Future<void> launchWebsite(BuildContext context, String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching website: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open website',
              style: TextStyle(color: botsWhite), // White text on red background
            ),
            backgroundColor: botsError, // Use AppDesignSystem error color
          ),
        );
      }
    }
  }

  /// Open WhatsApp chat
  static Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    final url = Uri.parse('https://wa.me/$phoneNumber?text=Hello');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open WhatsApp',
              style: TextStyle(color: botsWhite), // White text on red background
            ),
            backgroundColor: botsError, // Use AppDesignSystem error color
          ),
        );
      }
    }
  }

  /// Open email client
  static Future<void> sendEmail(BuildContext context, String email, {String subject = 'Hello'}) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=$subject',
    );
    try {
      await launchUrl(params, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching email: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open email app',
              style: TextStyle(color: botsWhite), // White text on red background
            ),
            backgroundColor: botsError, // Use AppDesignSystem error color
          ),
        );
      }
    }
  }

  /// Make phone call
  static Future<void> makeCall(BuildContext context, String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Cannot make call';
      }
    } catch (e) {
      debugPrint('Error calling phone: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not make call',
              style: TextStyle(color: botsWhite), // White text on red background
            ),
            backgroundColor: botsError, // Use AppDesignSystem error color
          ),
        );
      }
    }
  }

  /// Format date as DD/MM/YYYY
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Sliver app bar for profile screens
class ProfileSliverAppBar extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final bool isSameUser;

  const ProfileSliverAppBar({
    super.key,
    required this.title,
    this.imageUrl,
    required this.isSameUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 3,
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: Image.network(
                        imageUrl!,
                        width: 94,
                        height: 94,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: 48,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.business,
                              color: colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    )
                  : CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      child: imageUrl == null || imageUrl!.isEmpty
                          ? _buildInitials(title, colorScheme.onPrimaryContainer)
                          : Icon(
                              Icons.business,
                              color: colorScheme.primary,
                            ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Generate proper initials from company/name
  /// Examples: "Divine Creations" -> "DC", "ABC Company" -> "AC"
  Widget _buildInitials(String name, Color textColor) {
    // Extract proper initials from company name
    // Split by spaces and take first letter of each significant word
    final words = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    
    if (words.isEmpty) {
      initials = '?';
    } else if (words.length == 1) {
      // Single word: take first 2 characters if available
      final word = words[0];
      if (word.length >= 2) {
        initials = word.substring(0, 2).toUpperCase();
      } else {
        initials = word.substring(0, 1).toUpperCase();
      }
    } else {
      // Multiple words: take first letter of first 2 significant words
      // Skip common words like "the", "a", "an", "of", "and", "for"
      final skipWords = {'the', 'a', 'an', 'of', 'and', 'for', 'in', 'on', 'at', 'to'};
      final significantWords = words.where((w) => 
        w.isNotEmpty && !skipWords.contains(w.toLowerCase())
      ).take(2).toList();
      
      if (significantWords.length >= 2) {
        initials = (significantWords[0][0] + significantWords[1][0]).toUpperCase();
      } else if (significantWords.length == 1) {
        final word = significantWords[0];
        initials = word.length >= 2 
            ? word.substring(0, 2).toUpperCase()
            : word.substring(0, 1).toUpperCase();
      } else {
        // Fallback: use first two letters of first word
        final firstWord = words[0];
        initials = firstWord.length >= 2
            ? firstWord.substring(0, 2).toUpperCase()
            : firstWord.substring(0, 1).toUpperCase();
      }
    }
    
    return Text(
      initials,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}

/// Approval status badge
class ProfileApprovalBadge extends StatelessWidget {
  final String status;

  const ProfileApprovalBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = colorScheme.tertiary;
        badgeIcon = Icons.verified;
        badgeText = 'Verified';
        break;
      case 'pending':
        badgeColor = colorScheme.secondary;
        badgeIcon = Icons.pending;
        badgeText = 'Pending Approval';
        break;
      case 'rejected':
        badgeColor = colorScheme.error;
        badgeIcon = Icons.cancel;
        badgeText = 'Not Approved';
        break;
      default:
        badgeColor = colorScheme.onSurfaceVariant;
        badgeIcon = Icons.help;
        badgeText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 18, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section card with title and content
class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}

/// Action button for profile actions
class ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const ProfileActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusL),
          side: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }
}
