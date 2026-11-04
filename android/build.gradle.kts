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
// Certains plugins (ex. printing) déclarent une compileSdk plus basse (34),
// ce qui déclenche le téléchargement d'une plateforme SDK absente.
// On aligne tous les modules plugins sur la compileSdk de l'app (36).
// À enregistrer AVANT tout evaluationDependsOn, sinon les sous-projets sont
// déjà évalués et afterEvaluate lève une erreur.
subprojects {
    afterEvaluate {
        val androidExtension = extensions.findByName("android")
        when (androidExtension) {
            is com.android.build.api.dsl.ApplicationExtension -> androidExtension.compileSdk = 36
            is com.android.build.api.dsl.LibraryExtension -> androidExtension.compileSdk = 36
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
