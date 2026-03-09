pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
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
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}


// dependencyResolutionManagement {
//    repositories {
//        // 只使用阿里云镜像
//        maven { url = uri("https://maven.aliyun.com/repository/public") }
//        maven { url = uri("https://maven.aliyun.com/repository/google") }
//        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
//        // 注释掉原来的
//        // google()
//        // mavenCentral()
//        // gradlePluginPortal()
//    }
//}


include(":app")
