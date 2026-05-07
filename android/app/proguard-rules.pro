# ============================================================
# ProGuard / R8 Rules for FuelDost
# ============================================================

# Flutter engine — must NOT be removed/renamed
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Hive — keep TypeAdapters and annotated models
-keep class com.hivedb.** { *; }
-keep class * extends com.hive.** { *; }
-keepclassmembers class * {
    @com.hive.annotations.* <methods>;
}

# Keep all classes that extend HiveObject
-keep class * extends io.hive.** { *; }

# Geolocator / Location services
-keep class com.baseflow.geolocator.** { *; }

# Keep enum names (needed by Riverpod state classes)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# General Android
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
