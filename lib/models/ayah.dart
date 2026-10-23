enum TranslationMode {
  arabicOnly,
  englishOnly,
  arabicAndEnglish,
}

class Ayah {
  final int chapter;
  final int verse;
  final String arabicText;
  final String translation;
  final String? transliteration;

  Ayah({
    required this.chapter,
    required this.verse,
    required this.arabicText,
    required this.translation,
    this.transliteration,
  });

  factory Ayah.fromJson({
    required Map<String, dynamic> arabicJson,
    Map<String, dynamic>? translationJson,
    Map<String, dynamic>? transliterationJson,
  }) {
    return Ayah(
      chapter: arabicJson['chapter'] as int? ?? 1,
      verse: arabicJson['verse'] as int? ?? 1,
      arabicText: (arabicJson['text'] as String? ?? '').trim(),
      translation: (translationJson?['text'] as String? ?? '').trim(),
      transliteration: (transliterationJson?['text'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapter': chapter,
      'verse': verse,
      'arabicText': arabicText,
      'translation': translation,
      'transliteration': transliteration,
    };
  }

  factory Ayah.fromMap(Map<String, dynamic> map) {
    return Ayah(
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      arabicText: map['arabicText'] as String,
      translation: map['translation'] as String,
      transliteration: map['transliteration'] as String?,
    );
  }
}
