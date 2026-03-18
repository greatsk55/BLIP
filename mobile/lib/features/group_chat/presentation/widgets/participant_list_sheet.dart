import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/group_participant.dart';

/// 참여자 목록 바텀시트
class ParticipantListSheet extends StatelessWidget {
  final List<GroupParticipant> participants;
  final String myId;
  final bool isAdmin;
  final void Function(String userId) onKick;

  const ParticipantListSheet({
    super.key,
    required this.participants,
    required this.myId,
    required this.isAdmin,
    required this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ghostGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.groupParticipants(participants.length),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: signalGreen,
            ),
          ),
          const SizedBox(height: 12),
          ...participants.map((p) {
            final isMe = p.userId == myId;
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                p.isAdmin ? Icons.star : Icons.person_outline,
                color: p.isAdmin ? signalGreen : ghostGrey,
                size: 20,
              ),
              title: Text(
                '${p.username}${isMe ? ' (${l10n.groupYou})' : ''}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: p.isAdmin
                  ? Text(
                      l10n.groupAdmin,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: signalGreen.withValues(alpha: 0.6),
                      ),
                    )
                  : null,
              trailing: isAdmin && !isMe && !p.isAdmin
                  ? IconButton(
                      onPressed: () => onKick(p.userId),
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppColors.glitchRed, size: 20),
                    )
                  : null,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
