# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# ============================================================
# FLUTTER & DART
# ============================================================

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart
-dontwarn io.flutter.embedding.**
-ignorewarnings

# ============================================================
# SUPABASE & NETWORKING
# ============================================================

# OkHttp (usado pelo Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-dontwarn org.codehaus.mojo.animal_sniffer.*

# Retrofit & Gson (se usar)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# ============================================================
# MODELS & DATA CLASSES
# ============================================================

# Manter modelos de dados para serialização
-keep class com.suevit.distribuidora.models.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ============================================================
# REFLECTION
# ============================================================

# Manter anotações para reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ============================================================
# NATIVE METHODS
# ============================================================

# Manter métodos nativos
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================================
# SERIALIZATION
# ============================================================

# Manter membros necessários para serialização
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================================
# ENUMS
# ============================================================

# Manter enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================
# PARCELABLE
# ============================================================

# Manter classes Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ============================================================
# WEBKIT
# ============================================================

# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# ============================================================
# PLUGINS ESPECÍFICOS
# ============================================================

# Speech to Text
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# File Picker
-keep class androidx.** { *; }
-keep interface androidx.** { *; }

# Cached Network Image
-keep class com.baseflow.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Shared Preferences
-keep class com.google.android.gms.common.** { *; }

# ============================================================
# OPTIMIZATION FLAGS
# ============================================================

# Otimizações agressivas (pode causar problemas, testar bem!)
# -optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
# -optimizationpasses 5
# -allowaccessmodification

# Desabilitar warnings específicos se necessário
# -dontwarn javax.annotation.**
# -dontwarn org.conscrypt.**

# ============================================================
# DEBUGGING
# ============================================================

# Manter informações de linha para stack traces úteis
-keepattributes SourceFile,LineNumberTable

# Renomear apenas classes de terceiros (opcional)
# -keep class com.suevit.distribuidora.** { *; }

# ============================================================
# NOTAS
# ============================================================
# 
# 1. Sempre teste builds de release completamente após ativar ProGuard
# 2. Se algo quebrar, adicione regras -keep específicas aqui
# 3. Use 'flutter build apk --release --verbose' para ver logs detalhados
# 4. Para debugging de ProGuard: adicione -printconfiguration proguard-config.txt
# 5. Mapping file: build/app/outputs/mapping/release/mapping.txt (para desobfuscação de crashes)
#
# ============================================================
