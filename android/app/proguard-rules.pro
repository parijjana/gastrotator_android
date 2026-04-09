# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Service classes for SQLite and others
-keep class com.gastrotator.app.** { *; }

# Keep specific models that might be used for JSON serialization
-keepclassmembers class * {
  @google.gson.annotations.SerializedName <fields>;
}
