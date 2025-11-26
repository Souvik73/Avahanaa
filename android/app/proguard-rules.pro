# Keep Flutter embedding and plugin entrypoints so R8 does not strip them.
-keep class io.flutter.** { *; }

# Keep Firebase/Play Services code paths that are invoked via reflection.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Play Core split install classes used by Flutter deferred components.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
