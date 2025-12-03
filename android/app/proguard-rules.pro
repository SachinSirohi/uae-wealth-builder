# ProGuard configuration for release builds.

# Keep ML Kit text recognition classes to prevent R8 from stripping language-specific models.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Keep plugin entry points used via reflection.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Preserve Flutter's GeneratedPluginRegistrant.
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
