buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // **CORRECTED LINE FOR KOTLIN DSL**
        classpath("com.google.gms:google-services:4.4.0")

        // You might also need the Android Gradle Plugin classpath here
        // e.g., classpath("com.android.tools.build:gradle:8.0.0")
    }
}

allprojects {
    repositories {
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