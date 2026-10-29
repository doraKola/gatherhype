# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.android.gms.**

# OkHttp / HTTP
-dontwarn okhttp3.**
-dontwarn okio.**

# Shared Preferences
-keep class androidx.datastore.** { *; }

# Keep all model classes (for JSON parsing)
-keep class com.dor.gatherhype.** { *; }

# General
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn javax.annotation.**
