import java.util.Properties
import java.io.File
import java.io.FileInputStream

pluginManagement {
    val flutterSdkPath = try {
        val properties = Properties()
        val propertiesFile = File("local.properties")
        if (propertiesFile.exists()) {
            properties.load(FileInputStream(propertiesFile))
        }
        properties.getProperty("flutter.sdk")
    } catch (e: Exception) {
        null
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "android"
include(":app")

val flutterSdkPath = try {
    val properties = Properties()
    val propertiesFile = File("local.properties")
    if (propertiesFile.exists()) {
        properties.load(FileInputStream(propertiesFile))
    }
    properties.getProperty("flutter.sdk")
} catch (e: Exception) {
    null
}

if (flutterSdkPath != null) {
    settings.extra["flutterSdkPath"] = flutterSdkPath
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
} else {
    throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
}