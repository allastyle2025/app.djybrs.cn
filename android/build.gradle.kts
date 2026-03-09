buildscript {
    // 降级到稳定版本，避免高版本兼容性问题
    ext.kotlin_version = '1.9.0'
    repositories {
        // 1. 强制优先使用阿里云镜像，移除官方仓库的默认优先级
        maven { 
            url 'https://maven.aliyun.com/repository/google' 
            // 禁用快照缓存，确保每次都走镜像
            metadataSources { mavenPom() }
        }
        maven { 
            url 'https://maven.aliyun.com/repository/public' 
            metadataSources { mavenPom() }
        }
        // 2. 官方仓库仅作为最后的后备（实际不会走）
        google() {
            content {
                // 限制官方仓库仅解析阿里云没有的依赖（几乎没有）
                includeGroupByRegex 'com\\.android.*'
            }
        }
        mavenCentral() {
            content {
                includeGroupByRegex '.*'
            }
        }
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.20"
    }
}

allprojects {
    repositories {
        // 和 buildscript 保持完全一致的镜像优先级
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
    }
    
    // 核心：强制所有依赖优先使用项目配置的仓库，拦截 Flutter 插件的仓库覆盖
    configurations.all {
        resolutionStrategy {
            // 禁用动态依赖缓存，确保每次都重新解析仓库
            cacheChangingModulesFor 0, 'seconds'
            // 优先使用项目仓库，而非插件自带的仓库
            preferProjectRepositories()
            // 强制所有依赖从阿里云镜像解析
            eachDependency {
                if (requested.group.startsWith('com.android') || 
                    requested.group.startsWith('androidx') ||
                    requested.group.startsWith('org.jetbrains.kotlin')) {
                    useRepository {
                        name = 'Aliyun'
                        url = uri('https://maven.aliyun.com/repository/public')
                    }
                }
            }
        }
    }
}

// 保留你原本的构建目录自定义逻辑（建议暂时注释，先解决镜像问题后再启用）
// val newBuildDir: Directory =
//     rootProject.layout.buildDirectory
//         .dir("../../build")
//         .get()
// rootProject.layout.buildDirectory.value(newBuildDir)

// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }
// subprojects {
//     project.evaluationDependsOn(":app")
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}