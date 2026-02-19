import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

class RoomCreatedView extends StatelessWidget {
  final String roomId;
  final String password;

  const RoomCreatedView({
    super.key,
    required this.roomId,
    required this.password,
  });

  String get _roomLink {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://blip.app';
    return '$baseUrl/room/$roomId';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.check_circle_outline, size: 64, color: signalGreen),
          const SizedBox(height: 24),
          Text(l10n.chatCreatedTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),

          // ── Link display ──
          _InfoCard(
            label: 'LINK',
            isDark: isDark,
            signalGreen: signalGreen,
            ghostGrey: ghostGrey,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _roomLink,
                    style: TextStyle(
                      fontSize: 13,
                      color: signalGreen,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _roomLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.commonCopied)),
                    );
                  },
                  icon: Icon(Icons.copy, size: 18, color: signalGreen),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Password display ──
          _InfoCard(
            label: 'PASSWORD',
            isDark: isDark,
            signalGreen: signalGreen,
            ghostGrey: ghostGrey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  password,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: signalGreen,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.commonCopied)),
                    );
                  },
                  icon: Icon(Icons.copy, size: 18, color: signalGreen),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Share button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Share.share(l10n.chatShareMessage(_roomLink, password));
              },
              icon: const Icon(Icons.share),
              label: Text(l10n.commonShare),
            ),
          ),
          const SizedBox(height: 32),

          // ── Waiting indicator ──
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: 16),
          Text(
            l10n.chatWaitingPeer,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 링크/비밀번호 카드 공통 위젯
class _InfoCard extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color signalGreen;
  final Color ghostGrey;
  final Widget child;

  const _InfoCard({
    required this.label,
    required this.isDark,
    required this.signalGreen,
    required this.ghostGrey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: signalGreen.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: ghostGrey,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
