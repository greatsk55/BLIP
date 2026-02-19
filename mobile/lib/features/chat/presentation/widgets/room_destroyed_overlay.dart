import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

class RoomDestroyedOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const RoomDestroyedOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.voidBlackDark : AppColors.voidBlackLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_forever,
              size: 64,
              color: AppColors.glitchRed,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.chatDestroyedTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.glitchRed,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.chatDestroyedSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.glitchRed,
              ),
              child: Text(l10n.commonBack),
            ),
          ],
        ),
      ),
    );
  }
}
