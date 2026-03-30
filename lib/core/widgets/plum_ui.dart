import 'package:flutter/material.dart';
import 'package:neznakomets/core/theme/app_colors.dart';
import 'package:neznakomets/core/theme/app_text_styles.dart';

/// Фон экрана в стиле Plum Noir (как [HomeScreen]).
const BoxDecoration kPlumScreenDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment(-0.8, -1.0),
    end: Alignment(0.8, 1.0),
    colors: [
      AppColors.surfaceStart,
      AppColors.surfaceMid1,
      AppColors.surfaceMid2,
      AppColors.surfaceEnd,
    ],
    stops: [0.0, 0.30, 0.65, 1.0],
  ),
);

class PlumButton extends StatelessWidget {
  const PlumButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: AppColors.accent.withValues(alpha: 0.15),
        highlightColor: AppColors.accent.withValues(alpha: 0.08),
        child: Ink(
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.btnSolidStart,
                AppColors.btnSolidMid,
                AppColors.btnSolidEnd,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: AppColors.accent.a * 0.22),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.btnSolidShadow
                    .withValues(alpha: AppColors.btnSolidShadow.a * 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PlumGhostButton extends StatelessWidget {
  const PlumGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.minHeight = 44,
    this.fontSize = 11,
  });

  final String label;
  final VoidCallback onTap;
  final double minHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: AppColors.accent.withValues(alpha: 0.12),
        highlightColor: AppColors.accent.withValues(alpha: 0.07),
        child: Ink(
          height: minHeight,
          decoration: BoxDecoration(
            color: AppColors.btnGhostBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.accentFaint.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.button.copyWith(
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
                color: AppColors.homeGhostLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка «назад» в стиле шапки чата (ghost + chevron).
class PlumBackButton extends StatelessWidget {
  const PlumBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.accent.withValues(alpha: 0.12),
        highlightColor: AppColors.accent.withValues(alpha: 0.07),
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.btnGhostBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderRing1, width: 0.5),
          ),
          child: const Icon(
            Icons.chevron_left,
            color: AppColors.chatBackIcon,
            size: 18,
          ),
        ),
      ),
    );
  }
}
