# Flutter default rules
-dontwarn io.flutter.embedding.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_blue_plus
-keep class com.lib.flutter_blue_plus.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
}
