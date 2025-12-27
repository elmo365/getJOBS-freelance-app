# ProGuard rules for Bots Jobs Connect

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# AndroidX / Support Library
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class com.google.android.material.** { *; }

# Syncfusion
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# PDF Processing (pdfbox)
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**
-dontwarn com.gemalto.jp2.**
-keep class com.gemalto.jp2.** { *; }

# Google Generative AI
-keep class com.google.generativeai.** { *; }
-dontwarn com.google.generativeai.**

# Appwrite
-keep class io.appwrite.** { *; }

# Handle reflection-based serialization
-keepattributes Signature, *Annotation*, EnclosingMethod
-keep class com.example.freelance_app.models.** { *; }
