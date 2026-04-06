import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Custom YouSpotDL logo widget.
/// Shows a cyan gradient rounded square with a music-note icon
/// and a small download-arrow badge in the corner.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.40;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Music note — slightly top-left biased
          Positioned(
            top: size * 0.08,
            left: size * 0.10,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withValues(alpha: 0.95),
              size: size * 0.60,
            ),
          ),
          // Download badge — bottom-right corner
          Positioned(
            bottom: size * 0.06,
            right: size * 0.06,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: size * 0.025,
                ),
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: Colors.white,
                size: badgeSize * 0.60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

