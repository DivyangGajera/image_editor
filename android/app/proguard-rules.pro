# Release builds are shrunk and obfuscated by R8. ML Kit and Google Play
# services find their components by class name at runtime (component
# registrars, dynamite modules), so renamed or stripped classes make
# background removal crash with null-reference errors. Keep them intact.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_subject_segmentation.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
