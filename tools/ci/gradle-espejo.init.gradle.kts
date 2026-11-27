// Solo CI (spec 047). repo.maven.apache.org limita por IP (HTTP 429) y los runners de
// GitHub las comparten: las descargas de Maven Central se piden al espejo de Google.
// Se copia a ~/.gradle/init.d, así también aplica a la compilación incluida de Flutter.
import org.gradle.api.artifacts.dsl.RepositoryHandler
import org.gradle.api.artifacts.repositories.MavenArtifactRepository

val espejo = "https://maven-central.storage-download.googleapis.com/maven2/"
val centrales = setOf("repo.maven.apache.org", "repo1.maven.org")

// Redirige sin añadir repositorios: Flutter prohíbe declararlos por proyecto en su compilación.
fun redirigir(repositorios: RepositoryHandler) {
    repositorios.withType(MavenArtifactRepository::class.java).configureEach {
        if (url.host in centrales) setUrl(espejo)
    }
}

beforeSettings {
    redirigir(pluginManagement.repositories)
    redirigir(dependencyResolutionManagement.repositories)
    // El portal de plugins redirige a Maven Central; el espejo va antes para evitarlo.
    pluginManagement.repositories.google()
    pluginManagement.repositories.maven { setUrl(espejo) }
    pluginManagement.repositories.gradlePluginPortal()
}

beforeProject {
    redirigir(buildscript.repositories)
    redirigir(repositories)
}
