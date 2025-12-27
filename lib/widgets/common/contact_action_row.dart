import 'package:flutter/material.dart';
import 'package:freelance_app/utils/app_design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactActionRow extends StatelessWidget {
  final String? email;
  final String? phoneNumber;
  final bool compact;

  const ContactActionRow({
    super.key,
    this.email,
    this.phoneNumber,
    this.compact = false,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void _call() {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      _launchUrl('tel:$phoneNumber');
    }
  }

  void _email() {
    if (email != null && email!.isNotEmpty) {
      _launchUrl('mailto:$email');
    }
  }

  void _whatsapp() {
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      // Clean number for WhatsApp (remove + and spaces if needed, or keep +)
      // WhatsApp API format: https://wa.me/1234567890
      var cleanNumber = phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '');
      _launchUrl('https://wa.me/$cleanNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    if ((email == null || email!.isEmpty) && (phoneNumber == null || phoneNumber!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
         _ContactButton(
          icon: Icons.phone,
          label: 'Call',
          color: Colors.blue,
          onTap: _call,
          compact: compact,
        ),
        SizedBox(width: compact ? 8 : AppDesignSystem.spaceM),
        _ContactButton(
          icon: FontAwesomeIcons.whatsapp,
          label: 'WhatsApp',
          color: Colors.green,
          onTap: _whatsapp,
          compact: compact,
        ),
      ],
      if (email != null && email!.isNotEmpty) ...[
        SizedBox(width: compact ? 8 : AppDesignSystem.spaceM),
        _ContactButton(
          icon: Icons.email,
          label: 'Email',
          color: Colors.redAccent,
          onTap: _email,
          compact: compact,
        ),
      ],
    ];

    if (compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    return Row(children: children);
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 20),
        tooltip: label,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
