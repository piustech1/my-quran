# Privacy Policy for My Quran

**Application:** My Quran (`com.piustech.my_quran`)  
**Developer:** PiusTech  
**Last Updated:** October 25, 2026  
**Web Version:** [https://piustech1.github.io/my-quran/](https://piustech1.github.io/my-quran/)

---

## 1. Overview
My Quran is built with strict privacy-by-design principles. We do not collect, sell, monetize, or track any personal user data. All religious preferences and prayer settings remain strictly on your personal device.

## 2. Information We Do NOT Collect
- **No Account Registration:** You do not need to create an account, log in, or provide your name, email, or phone number to use My Quran.
- **No Personal Identity Tracking:** We do not collect unique advertising identifiers (GAID), biometric data, contacts, or photos.
- **No Selling of Data:** We never sell, rent, or trade user data to advertisers, data brokers, or third parties.

## 3. Information We Process & Device Permissions
To provide essential Islamic services (accurate prayer times, Adhan alarms, and audio streaming), the app requests the following specific permissions:
- **Location Data (Approximate / IP-Based):** Used solely to determine your city and latitude/longitude to calculate astronomical prayer times (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha) and local weather conditions. Your location is processed locally or via IP geocoding and is never logged, stored on external servers, or used for tracking.
- **Exact Alarms (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`):** Required by the Android operating system to wake the device at the exact minute of each prayer time to play the Adhan and show reminder alerts.
- **Notifications (`POST_NOTIFICATIONS`):** Used exclusively to deliver timely prayer time alerts, Daily Ayah notifications, and audio playback controls.
- **Foreground Service (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`):** Allows seamless Quran recitation audio and Adhan playback to continue uninterrupted when you lock your screen or switch apps.
- **Network Access (`INTERNET`):** Used to fetch public Quranic text, audio recitation files, weather forecasts, and Islamic Reels media streams.

## 4. Local Data Storage on Your Device
My Quran stores preferences locally on your device using Android Shared Preferences, including:
- Chosen reciter, translation edition, and font size.
- Bookmarks and daily Ayah reflections.
- Prayer notification toggles.
- Liked Islamic Reels.

This data never leaves your device and is erased if you uninstall the app or clear app data.

## 5. Third-Party Services & Open APIs
My Quran retrieves verified public religious and environmental data through open APIs:
- **Quran Text & Translations:** Open-source CDN endpoints (`fawazahmed0/quran-api`).
- **Recitation Audio:** Streamed from EveryAyah public repository (`everyayah.com`).
- **Islamic Media:** Educational video streams sourced from IslamHouse API (`api3.islamhouse.com`).
- **Weather Information:** Open-Meteo weather API (`open-meteo.com`).
- **Geolocation:** Free public IP geolocation (`ipwho.is`).

None of these services receive any personally identifiable information from your device.

## 6. Children's Privacy
My Quran is safe for users of all ages, including families and children. We do not solicit or knowingly collect personal information from children under 13.

## 7. Contact Us
If you have any questions regarding this Privacy Policy, please contact:
- **Developer:** PiusTech
- **Email:** support@piustech.com
- **Repository:** [https://github.com/piustech1/my-quran](https://github.com/piustech1/my-quran)
