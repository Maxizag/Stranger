import 'package:flutter/material.dart';

class AppColors {
  // --- Фоны ---
  static const Color bgPage = Color(0xFF0D0D0D);
  static const Color bgGradStart = Color(0xFF351E28); // Plum Noir
  static const Color bgGradMid1 = Color(0xFF2A1F2E);
  static const Color bgGradMid2 = Color(0xFF1A1A1A);
  static const Color bgGradEnd = Color(0xFF0D0D0D);

  // --- Фон экрана телефона (внутри Scaffold) ---
  static const Color surfaceStart = Color(0xFF2C1E26);
  static const Color surfaceMid1 = Color(0xFF201820);
  static const Color surfaceMid2 = Color(0xFF141214);
  static const Color surfaceEnd = Color(0xFF0E0C0F);

  // --- Акцентный (Plum Rose) ---
  static const Color accent = Color(0xFFC37D94); // rgba(195,125,148)
  static const Color accentDim = Color(0xFFAF6478); // для иконок/обводок
  static const Color accentFaint = Color(0xFF5A2838); // для тонких деталей

  // --- Текст ---
  static const Color textPrimary = Color(0xFFEBD7DE); // rgba(235,215,222) заголовок
  static const Color textAccent = Color(0xFFFFFFFF); // акцентное слово в заголовке
  static const Color textBody = Color(0xFF82596A); // rgba(130,90,105) подзаголовок
  static const Color textMuted = Color(0xFF503040); // rgba(160,105,125) плейсхолдер/кнопка ghost

  // --- Eyebrow / tag ---
  static const Color textEyebrow = Color(0xFFB46E87); // rgba(180,110,135, 0.38)

  // --- Dots ---
  static const Color dotInactive = Color(0xFF502837);
  static const Color dotActive = Color(0xFFAF6479); // rgba(175,100,125)

  // --- Кнопки ---
  static const Color btnGhostBg = Color(0x4A351E28); // rgba(53,30,40,0.28)
  static const Color btnGhostText = Color(0x8CA0697D); // rgba(160,105,125,0.55)
  static const Color btnSolidStart = Color(0xFF4D2838);
  static const Color btnSolidMid = Color(0xFF351E28);
  static const Color btnSolidEnd = Color(0xFF271520);
  static const Color btnSolidText = Color(0xF2E6C3D2); // rgba(230,195,210,0.95)

  // --- Ambient glow per slide ---
  static const Color glowSlide0 = Color(0xFFD08098); // розовый
  static const Color glowSlide1 = Color(0xFF9080C0); // фиолетовый
  static const Color glowSlide2 = Color(0xFFB07090); // сливовый

  // --- Borders ---
  static const Color borderSurface = Color(0x24A05A73); // rgba(160,90,115,0.14)
  static const Color borderIcon = Color(0x33B46E87); // rgba(180,110,135,0.2)
  static const Color borderRing1 = Color(0x1EA05A73); // rgba(160,90,115,0.12)
  static const Color borderRing2 = Color(0x12A05A73); // rgba(160,90,115,0.07)
  static const Color borderRing3 = Color(0x0AA05A73); // rgba(160,90,115,0.04)
}
