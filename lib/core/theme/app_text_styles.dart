import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Заголовки: Syne (Google Fonts). Остальное: Inter.
class AppTextStyles {
  static final TextStyle onboardingTitle = GoogleFonts.syne(
    fontWeight: FontWeight.w800,
    fontSize: 30,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static final TextStyle onboardingTitleAccent = GoogleFonts.syne(
    fontWeight: FontWeight.w800,
    fontSize: 30,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textAccent,
    shadows: const [
      Shadow(
        color: Color(0x33C8829B), // rgba(200,130,155,0.2)
        blurRadius: 28,
      ),
    ],
  );

  static final TextStyle onboardingBody = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.75,
    letterSpacing: 0.3,
    color: AppColors.textBody,
  );

  static final TextStyle eyebrow = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 10,
    letterSpacing: 1.0,
    color: AppColors.textEyebrow,
  );

  static final TextStyle slideTag = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 9,
    letterSpacing: 2.2,
    color: AppColors.textEyebrow,
  );

  static final TextStyle button = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    letterSpacing: 1.0,
    color: AppColors.btnSolidText,
  );

  static final TextStyle skip = GoogleFonts.inter(
    fontWeight: FontWeight.w300,
    fontSize: 11,
    letterSpacing: 0.5,
    color: AppColors.textMuted,
  );
}
