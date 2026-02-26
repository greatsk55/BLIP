import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

class RoomCreatedView extends StatefulWidget {
  final String roomId;
  final String password;

  const RoomCreatedView({
    super.key,
    required this.roomId,
    required this.password,
  });

  @override
  State<RoomCreatedView> createState() => _RoomCreatedViewState();
}

class _RoomCreatedViewState extends State<RoomCreatedView> {
  bool _includeKey = true;

  String get _baseLink {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://blip.app';
    return '$baseUrl/room/${widget.roomId}';
  }

  String get _shareLink {
    if (_includeKey) {
      return '$_baseLink?k=${Uri.encodeComponent(widget.password)}';
    }
    return _baseLink;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonCopied),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Title ──
              Text(
                l10n.chatCreatedTitle.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 6,
                  color: signalGreen,
                ),
              ),
              const SizedBox(height: 32),

              // ── ACCESS KEY (항상 표시 - 웹과 동일) ──
              Text(
                l10n.chatAccessKey.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 3,
                  color: ghostGrey.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: signalGreen.withValues(alpha: 0.2)),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.password,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 8,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyIcon(
                      onTap: () => _copy(widget.password),
                      color: ghostGrey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── SHARE LINK ──
              Text(
                l10n.chatShareLink.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 3,
                  color: ghostGrey.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareLink,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: ghostGrey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyIcon(
                      onTap: () => _copy(_shareLink),
                      color: ghostGrey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Include key toggle ──
              GestureDetector(
                onTap: () => setState(() => _includeKey = !_includeKey),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _includeKey
                            ? signalGreen.withValues(alpha: 0.8)
                            : ghostGrey.withValues(alpha: 0.2),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _includeKey
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.voidBlackDark
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.chatIncludeKey.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: ghostGrey.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Include key warning ──
              if (_includeKey)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    l10n.chatIncludeKeyWarning.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1,
                      color: ghostGrey.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              if (!_includeKey) const SizedBox(height: 24),

              // ── Security warning (glitch-red) ──
              Text(
                l10n.chatCreatedWarning.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: AppColors.glitchRed.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),

              // ── Peer status (pulsing text) ──
              _PulsingText(
                text: l10n.chatWaitingPeer.toUpperCase(),
                color: ghostGrey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 32),

              // ── Share button ──
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    if (_includeKey) {
                      Share.share(
                          l10n.chatShareMessageLinkOnly(_shareLink));
                    } else {
                      Share.share(l10n.chatShareMessage(
                          _shareLink, widget.password));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: signalGreen),
                    foregroundColor: signalGreen,
                    shape: const RoundedRectangleBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      letterSpacing: 3,
                    ),
                  ),
                  child: Text(l10n.commonShare.toUpperCase()),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// 복사 아이콘 (탭 시 체크 피드백 - 웹 CopyButton과 동일)
class _CopyIcon extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;

  const _CopyIcon({required this.onTap, required this.color});

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  bool _copied = false;

  void _handleTap() {
    widget.onTap();
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _copied
              ? Icon(Icons.check, size: 16, color: widget.color,
                  key: const ValueKey('check'))
              : Icon(Icons.copy, size: 16, color: widget.color,
                  key: const ValueKey('copy')),
        ),
      ),
    );
  }
}

/// 펄싱 텍스트 (웹의 animate-pulse 재현)
class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;

  const _PulsingText({required this.text, required this.color});

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Text(
        widget.text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          letterSpacing: 3,
          color: widget.color,
        ),
      ),
    );
  }
}
