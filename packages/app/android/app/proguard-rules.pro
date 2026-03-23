# WeGig - ProGuard Rules
# Configurações de ofuscação para builds de produção

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }

# Image Processing
-keep class com.fluttercandies.** { *; }

# Preserve annotations
-keepattributes *Annotation*

# TikTok Business SDK
-keep class com.tiktok.** { *; }
-keep class com.android.billingclient.api.** { *; }
-keep class androidx.lifecycle.** { *; }
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-dontwarn com.android.billingclient.api.**

# Flutter Play Store deferred components (not used but referenced)
-dontwarn com.google.android.play.core.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep model classes (Firestore serialization)
-keep class com.example.to_sem_banda.models.** { *; }

# Crashlytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Facebook SDK
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Image Cropper (uses reflection for layout)
-keep class com.yalantis.ucrop.** { *; }
-keep interface com.yalantis.ucrop.** { *; }

# Geolocator / Location
-keep class com.google.android.gms.location.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# Local Notifications
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Network / Caching (OkHttp, Glide)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.**

# Permissions handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.**

# AndroidX
-keep class androidx.appcompat.** { *; }
-keep class androidx.exifinterface.** { *; }
-keep class androidx.browser.customtabs.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Suppress warnings
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# General Android optimization
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Preserve some methods for better crash reports
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
