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

subprojects {
    val applySubprojectConfig: Project.() -> Unit = {
        extensions.findByName("android")?.let { androidExt ->
            try {
                val method = androidExt.javaClass.methods.firstOrNull {
                    it.name == "compileSdkVersion" &&
                    it.parameterTypes.size == 1 &&
                    (it.parameterTypes[0] == Int::class.javaPrimitiveType || it.parameterTypes[0] == java.lang.Integer::class.java)
                }
                method?.invoke(androidExt, 36)
            } catch (_: Throwable) {}
        }
    }

    if (state.executed) {
        applySubprojectConfig()
    } else {
        afterEvaluate {
            applySubprojectConfig()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

