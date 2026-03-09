pluginManagement {
    repositories {
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/public")
        //google()
        //mavenCentral()
        //gradlePluginPortal()
    }

    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    //repositories {
        //google()
        //mavenCentral()
        //gradlePluginPortal()
    //}
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 修改为实际存在的 AGP 版本
    id("com.android.application") version "8.7.3" apply false
    // 修改为兼容的 Kotlin 版本
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
}


dependencyResolutionManagement {
    repositories {
        // 只使用阿里云镜像
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        // 注释掉原来的
        // google()
        // mavenCentral()
        // gradlePluginPortal()
    }
}


include(":app")
