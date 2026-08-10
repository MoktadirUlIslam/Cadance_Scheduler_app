// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: File = rootProject.layout.buildDirectory.file("../../build").get().asFile
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: File = newBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}