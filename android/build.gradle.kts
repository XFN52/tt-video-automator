allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.arthenica.com") }
        maven { url = uri("https://jitpack.io") }
    }
}

val buildDirFile = File("C:/tmp/tt_build")
if (!buildDirFile.exists()) {
    buildDirFile.mkdirs()
}
val newBuildDir: Directory = layout.projectDirectory.dir("C:/tmp/tt_build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (androidExt != null && androidExt.namespace == null) {
            androidExt.namespace = "dev.isar.${project.name.replace("-", "_")}"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
