import 'package:flutter/material.dart';
import 'package:everroute/core/env.dart';
import 'package:everroute/ui/screens/assignments/widgets/assignment_card_action_button.dart';

/// Family share URL + actions (copy, email sheet, create token).
///
/// Used on the expanded assignment list card. [data] is the assignment map
/// (`share_token`, `share_token_expires_at`, `share_token_one_time`).
class AssignmentFamilyLinkSection extends StatelessWidget {
  const AssignmentFamilyLinkSection({
    super.key,
    required this.data,
    required this.busy,
    required this.onCopy,
    required this.onShare,
    required this.onCreate,
  });

  final Map<String, dynamic> data;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final raw = data['share_token']?.toString().trim() ?? '';
    final shareUrl = raw.isNotEmpty ? AppEnv.familyShareUrlForToken(raw) : null;
    final expiresIso = data['share_token_expires_at']?.toString();
    final oneTime = data['share_token_one_time'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Family status link',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Share a link so families can see assignment status without signing in. '
          'Only send links through your usual secure channels.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (shareUrl != null) ...[
          SelectableText(
            shareUrl,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          AssignmentCardActionButton(
            label: 'Copy Link',
            icon: Icons.copy,
            busy: busy,
            onPressed: onCopy,
            tone: AssignmentCardActionTone.primary,
          ),
          const SizedBox(height: 8),
          AssignmentCardActionButton(
            label: 'Share Link',
            icon: Icons.send,
            busy: busy,
            onPressed: onShare,
            tone: AssignmentCardActionTone.primary,
          ),
          if (expiresIso != null && expiresIso.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Expires: $expiresIso',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (oneTime)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'One-time: the first successful open consumes this link.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ] else ...[
          AssignmentCardActionButton(
            label: 'Create & share link',
            icon: Icons.link,
            busy: busy,
            onPressed: onCreate,
            tone: AssignmentCardActionTone.primary,
          ),
        ],
      ],
    );
  }
}
