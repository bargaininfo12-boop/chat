# Keep the names of classes, methods, and fields
-keep class com.example.myapp.** { *; }

# Do not obfuscate the names of classes, methods, and fields
-dontobfuscate

# Keep the line numbers for debugging
-keepattributes SourceFile,LineNumberTable

# Keep the annotations
-keepattributes *Annotation*

# Keep the names of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}


