# ProGuard / R8 rules for BrainForge

# Preserve Flutter engine & plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Preserve SharedPreferences plugin and Pigeon API registrars
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keepclassmembers class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.pigeon.shared_preferences_android.** { *; }
-keepclassmembers class dev.flutter.pigeon.shared_preferences_android.** { *; }

# Preserve Kotlin types used in asynchronous Pigeon / Dart JNI interop (package:jni)
-keep class kotlin.Unit { *; }
-keepclassmembers class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keepclassmembers class kotlin.Result { *; }
-keep class kotlin.Result$* { *; }
-keepclassmembers class kotlin.Result$* { *; }
-keep class kotlin.coroutines.** { *; }
-keepclassmembers class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keepclassmembers class kotlinx.coroutines.** { *; }

# Suppress Play Store deferred component warnings when Play Core is not included
-dontwarn com.google.android.play.core.**
