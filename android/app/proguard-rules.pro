# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Billing (for future IAP)
-keep class com.android.vending.billing.** { *; }

# Google Sign-In (for Google Drive sync)
-keep class com.google.android.gms.** { *; }

# SQLite / Drift
-keep class org.sqlite.** { *; }

# Crypto (for sync encryption)
-keep class org.bouncycastle.** { *; }

# ML Kit (for receipt OCR)
-keep class com.google.mlkit.** { *; }

# Play Core (deferred components / split install)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ML Kit optional script recognizers (not used, suppress warnings)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
