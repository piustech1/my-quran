import 'package:flutter/material.dart';

class NoorColors {
  static const emeraldNight = Color(0xFF0A1F13);
  static const emeraldDeep  = Color(0xFF0D2818);
  static const emerald      = Color(0xFF143D28);
  static const emeraldMid   = Color(0xFF1F5A3A);
  static const forest       = Color(0xFF1B4332);
  static const gold         = Color(0xFFD4AF37);
  static const goldBright   = Color(0xFFF3C64F);
  static const goldLight    = Color(0xFFF3C64F);
  static const goldPale     = Color(0xFFFCE7A0);
  static const goldDark     = Color(0xFFA9821F);
  static const cream        = Color(0xFFFDFBF7);
  static const ivory        = Color(0xFFFFFDF9);
  static const surface      = Color(0xFFFFFDF9);
  static const field        = Color(0xFFF4F1EA);
  static const inputBg      = Color(0xFFF4F1EA);
  static const fieldBorder  = Color(0xFFE2DED4);
  static const sand         = Color(0xFFE2DED4);
  static const line         = Color(0xFFE2DED4);
  static const ink          = Color(0xFF1F2A24);
  static const inkSoft      = Color(0xFF6B7069);
  static const destructive  = Color(0xFFC0392B);
  static const success      = Color(0xFF166534);
}

class NoorRadii {
  static const sheet  = BorderRadius.vertical(top: Radius.circular(32));
  static const field  = BorderRadius.all(Radius.circular(16));
  static const button = BorderRadius.all(Radius.circular(16));
  static const pill   = BorderRadius.all(Radius.circular(50));
}

class NoorShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 30,
      offset: Offset(0, 10),
    ),
  ];
  static const sheet = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 30,
      offset: Offset(0, -10),
    ),
  ];
  static const primaryButton = [
    BoxShadow(
      color: Color(0x8C0D2818),
      blurRadius: 28,
      spreadRadius: -12,
      offset: Offset(0, 14),
    ),
  ];
  static const avatarGlow = [
    BoxShadow(
      color: Color(0x40D4AF37),
      blurRadius: 25,
      spreadRadius: 0,
      offset: Offset(0, 0),
    ),
  ];
}

class NoorGradients {
  static const heroRadial = RadialGradient(
    center: Alignment(0, -0.24),
    radius: 1.1,
    colors: [
      Color(0xFF1F5A3A),
      Color(0xFF143D28),
      Color(0xFF0A1F13),
    ],
    stops: [0.0, 0.38, 1.0],
  );
  static const emeraldRadial = heroRadial;
  static const primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NoorColors.forest, NoorColors.emeraldDeep],
  );
  static const goldMetal = LinearGradient(
    colors: [NoorColors.goldPale, NoorColors.goldLight, NoorColors.goldDark],
  );
}
