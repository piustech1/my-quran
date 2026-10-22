# 📖 My Quran (Android)

An elegant, modern Quran application built with **Flutter**, designed around a deep imperial emerald aesthetic, clean iOS-style frosted glassmorphism, authentic 3D page-turn transitions, and offline-first reading.

Powered by the open [fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api).

---

## ✨ Features

- **Deep Imperial Emerald Theme:** Designed with rich `#0D3B2E` solid tones, warm manuscript parchment, and champagne gold accents (no gradients).
- **iOS-Style Frosted Glassmorphism:** Clean translucency with hairline borders and backdrop blur.
- **3D Book Page-Turn Mode:** Realistic 3D perspective page-opening and curling transitions.
- **Verse-by-Verse Study Mode:** Side-by-side Arabic Uthmani text, English translation, and Ayah copy actions.
- **Complete Quran Index:** All 114 Surahs and 30 Juzs with instant search by Arabic name, English name, and number.
- **Last Read & Bookmarks:** Automatically saves reading progress and allows bookmarking favorite Surahs.
- **Offline Caching:** Uses local storage so previously loaded chapters can be read without internet.
- **Customizable Typography:** Adjustable Arabic font size and translation toggle.

---

## 📲 Download & Installation

The latest release APK is built automatically and published directly under [**Releases**](https://github.com/piustech1/my-quran/releases).

1. Go to the [Releases page](https://github.com/piustech1/my-quran/releases).
2. Download `My-Quran-v1.0.0.apk`.
3. Open and install on any Android device.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter 3.24+ / Dart 3.5+
- **Platform:** Android (with iOS readiness)
- **Data Source:** [fawazahmed0/quran-api](https://github.com/fawazahmed0/quran-api) (via jsDelivr CDN with GitHub raw fallback)
- **Typography:** `google_fonts` (Amiri for Arabic, Plus Jakarta Sans for UI)
- **Local Persistence:** `shared_preferences`
- **CI/CD:** GitHub Actions (Direct release publishing via `softprops/action-gh-release`)
