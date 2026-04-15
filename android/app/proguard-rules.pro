# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Service classes for SQLite and others
-keep class com.gastrotator.app.** { *; }

# Suppress Play Core warnings (referenced by Flutter engine but not used)
-dontwarn com.google.android.play.core.**

# Keep specific models that might be used for JSON serialization
-keepclassmembers class * {
  @google.gson.annotations.SerializedName <fields>;
}
