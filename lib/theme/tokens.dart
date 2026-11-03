import 'package:flutter/material.dart';

class NoorColors {
  static const emeraldDeep = Color(0xFF0D2818);
  static const emerald     = Color(0xFF133E29);
  static const emeraldMid  = Color(0xFF1B5A3A);
  static const forest      = Color(0xFF1B4332);
  static const gold        = Color(0xFFD4AF37);
  static const goldLight   = Color(0xFFF3C64F);
  static const goldPale    = Color(0xFFFCE7A0);
  static const goldDark    = Color(0xFFA9821F);
  static const cream       = Color(0xFFFDFBF7);
  static const surface     = Color(0xFFFFFDF9);
  static const inputBg     = Color(0xFFF4F1EA);
  static const line        = Color(0xFFE2DED4);
  static const ink         = Color(0xFF13261B);
  static const destructive = Color(0xFFC0392B);
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
      color: Color(0x14000000),
      blurRadius: 30,
      offset: Offset(0, -10),
    ),
  ];
  static const primaryButton = [
    BoxShadow(
      color: Color(0x990D2818),
      blurRadius: 24,
      spreadRadius: -10,
      offset: Offset(0, 10),
    ),
  ];
}

class NoorGradients {
  static const emeraldRadial = RadialGradient(
    center: Alignment(0, -0.6),
    radius: 1.2,
    colors: [NoorColors.emeraldMid, NoorColors.emerald, NoorColors.emeraldDeep],
    stops: [0.0, 0.45, 1.0],
  );
  static const primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NoorColors.forest, NoorColors.emerald, NoorColors.emeraldDeep],
    stops: [0.0, 0.6, 1.0],
  );
  static const goldMetal = LinearGradient(
    colors: [NoorColors.goldPale, NoorColors.goldLight, NoorColors.goldDark],
  );
}
