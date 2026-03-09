buildscript {
    repositories {
        // 1. 首先使用阿里云镜像（它包含完整的 Google 和 Central 代理）
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        // 2. 然后添加 Google 官方仓库作为备份（但流量会优先走镜像）
        google()
        // 3. 最后是 Maven Central
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20"
    }
}

allprojects {
    repositories {
        // 使用完全相同的顺序
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
    }
}



val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
