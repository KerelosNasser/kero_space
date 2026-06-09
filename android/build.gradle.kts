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

    afterEvaluate {
        try {
            val android = project.extensions.getByName("android")
            val namespaceProperty = android.javaClass.getMethod("getNamespace").invoke(android) as String?
            if (namespaceProperty == null) {
                val groupStr = project.group.toString()
                val targetNamespace = if (groupStr.isNotEmpty()) groupStr else "dev.flutter.plugin." + project.name
                android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, targetNamespace)
            }
            try {
                android.javaClass.getMethod("setCompileSdk", Integer.TYPE).invoke(android, 36)
            } catch (e: Exception) {
                android.javaClass.getMethod("setCompileSdkVersion", Integer.TYPE).invoke(android, 36)
            }
        } catch (e: Exception) {}
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
