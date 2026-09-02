allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Alinea el target de JVM de los módulos Kotlin con el de Java (11).
    // Evita "Inconsistent JVM-target compatibility ... compileReleaseJavaWithJavac (11)
    // y compileReleaseKotlin (1.8)" (p. ej. en el plugin flutter_timezone).
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "11"
        }
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
