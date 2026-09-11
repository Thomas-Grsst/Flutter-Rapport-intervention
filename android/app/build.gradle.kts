import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clé de publication, quand il y en a une.
//
// `android/key.properties` désigne le magasin de clés et ses mots de passe.
// Ni l'un ni l'autre n'est versionné (voir .gitignore) : une clé de
// publication qui circule permet à n'importe qui de signer une mise à jour au
// nom de l'application. Tant que le fichier est absent, la compilation
// continue avec la clé de débogage, ce qui suffit pour installer l'APK à la
// main.
val fichierCle = rootProject.file("key.properties")
val cle =
    Properties().apply {
        if (fichierCle.exists()) {
            fichierCle.inputStream().use { load(it) }
        }
    }

android {
    namespace = "fr.auservicedeleau.rapport_intervention"
    compileSdk = flutter.compileSdkVersion

    // Le NDK est nécessaire même sans une ligne de code natif : le moteur
    // Flutter livre un `libflutter.so` de 165 Mo par architecture, que Gradle
    // dépouille de ses symboles de débogage au moment d'empaqueter l'APK avec
    // l'outil `strip` du NDK. Sans ce dépouillement, l'APK dépasse 490 Mo.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "fr.auservicedeleau.rapport_intervention"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (fichierCle.exists()) {
            create("release") {
                storeFile = cle.getProperty("storeFile")?.let { file(it) }
                storePassword = cle.getProperty("storePassword")
                keyAlias = cle.getProperty("keyAlias")
                keyPassword = cle.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sans clé de publication, on signe avec celle de débogage : l'APK
            // s'installe quand même à la main. Mais une mise à jour ne
            // remplace une application installée que si elle porte la même
            // signature — d'où l'intérêt d'une vraie clé dès qu'un téléphone
            // porte l'application pour de bon.
            signingConfig =
                if (fichierCle.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
