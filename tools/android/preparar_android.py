#!/usr/bin/env python3
"""Deja la carpeta android/ de la app lista para producción (specs 048-051).

Uso (desde la raíz del repo, después de `flutter create .` o con tu android/):
    python3 tools/android/preparar_android.py src/mobile/nexo_app

Es idempotente: solo agrega lo que falta y dice qué cambió.
- AndroidManifest: allowBackup=false, sin tráfico en claro, permisos mínimos
  (INTERNET, ubicación, notificaciones) y <queries> para enlaces/llamadas.
- app/build.gradle.kts: minSdk 24, firma de release con key.properties y el
  plugin de Google Services solo si existe google-services.json.
- settings.gradle.kts: declara el plugin de Google Services.
"""
import pathlib
import re
import sys

app = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "src/mobile/nexo_app")
android = app / "android"
cambios = []

if not android.exists():
    print(f"No existe {android}. Corre `flutter create --platforms=android .` dentro de {app} primero.")
    sys.exit(1)

# ---------------------------------------------------------------- manifest
mf = android / "app/src/main/AndroidManifest.xml"
m = mf.read_text(encoding="utf-8")
orig = m

def set_attr(text, name, value):
    tag = re.search(r"<application\b[^>]*>", text, re.S).group(0)
    if re.search(rf'android:{name}\s*=', tag):
        nuevo = re.sub(rf'android:{name}\s*=\s*"[^"]*"', f'android:{name}="{value}"', tag)
    else:
        nuevo = tag.replace("<application", f'<application\n        android:{name}="{value}"', 1)
    return text.replace(tag, nuevo, 1)

m = set_attr(m, "allowBackup", "false")
m = set_attr(m, "fullBackupContent", "false")
m = set_attr(m, "usesCleartextTraffic", "false")

for perm in ("INTERNET", "ACCESS_COARSE_LOCATION", "ACCESS_FINE_LOCATION", "POST_NOTIFICATIONS"):
    if f"android.permission.{perm}" not in m:
        m = m.replace("<application", f'<uses-permission android:name="android.permission.{perm}" />\n    <application', 1)

if "<queries>" not in m:
    m = m.replace("</manifest>", "    <queries>\n    </queries>\n</manifest>", 1)
# url_launcher (Android 11+): abrir la landing, mapas y llamadas.
for esquema, accion in (("https", "VIEW"), ("tel", "DIAL")):
    if f'android:scheme="{esquema}"' not in m:
        intent = (f'        <intent>\n            <action android:name="android.intent.action.{accion}" />\n'
                  f'            <data android:scheme="{esquema}" />\n        </intent>\n')
        m = re.sub(r"\n[ \t]*</queries>", lambda _: "\n" + intent + "    </queries>", m, count=1)

# Enlaces nexolocal:// (avisos push y landing) hacia la actividad principal.
if 'android:scheme="nexolocal"' not in m:
    filtro = """            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="nexolocal" />
            </intent-filter>
"""
    m = re.sub(r"(<activity\b[^>]*android:name=\"\.MainActivity\"[\s\S]*?)(</activity>)",
               lambda x: x.group(1).rstrip() + "\n" + filtro + "        " + x.group(2), m, count=1)

if m != orig:
    mf.write_text(m, encoding="utf-8")
    cambios.append(str(mf))

# ------------------------------------------------------------- app gradle
g_path = android / "app/build.gradle.kts"
g = g_path.read_text(encoding="utf-8")
g0 = g
g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24", g)
g = re.sub(r"minSdk\s*=\s*(1\d|2[0-3])\b", "minSdk = 24", g)

if "key.properties" not in g:
    # En .kts los import van antes de todo.
    if "import java.util.Properties" not in g:
        g = "import java.util.Properties\nimport java.io.FileInputStream\n\n" + g
    cabecera = """// Firma de release (spec 048): key.properties y la llave NO se suben al repo.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

"""
    # después del bloque plugins { … }
    g = re.sub(r"(plugins\s*\{[\s\S]*?\n\}\n)", lambda x: x.group(1) + "\n" + cabecera.rstrip("\n") + "\n", g, count=1)
    firma = """    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

"""
    g = re.sub(r"(\n    buildTypes\s*\{)", "\n" + firma.rstrip("\n") + r"\1", g, count=1)
    g = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
               'signingConfig = if (keystoreProperties.isNotEmpty()) signingConfigs.getByName("release") '
               'else signingConfigs.getByName("debug")', g)

# R8 (release): al excluir firebase-iid, ML Kit se queda con una referencia
# colgando a FirebaseInstanceId. Solo la usa el camino de modelos alojados en
# Firebase, que esta app no utiliza (usa el modelo base incluido).
pr = android / "app/proguard-rules.pro"
if not pr.exists():
    pr.write_text(
        "# Modelos de ML Kit alojados en Firebase: no se usan (modelo base incluido).\n"
        "-dontwarn com.google.firebase.iid.FirebaseInstanceId\n",
        encoding="utf-8",
    )
    cambios.append(str(pr))

if "proguard-rules.pro" not in g:
    g = re.sub(
        r"(\n        release \{\n)",
        r'\1            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")\n',
        g,
        count=1,
    )

if "firebase-iid" not in g:
    # ML Kit (com.google.mlkit:linkfirebase) arrastra firebase-iid 20.1.5, cuyas
    # clases ya vienen en firebase-messaging 24.x: sin esto, el release falla en
    # :app:checkReleaseDuplicateClasses (verificado, specs 049/050).
    g += """
configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}
"""

if "google-services" not in g:
    g += """
// Push (spec 050): solo si existe google-services.json (lo escribe el CI desde
// el secreto, o lo copias tú de la consola de Firebase; no se sube al repo).
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
"""
if g != g0:
    g_path.write_text(g, encoding="utf-8")
    cambios.append(str(g_path))

# ------------------------------------------------------------ settings
s_path = android / "settings.gradle.kts"
if s_path.exists():
    s = s_path.read_text(encoding="utf-8")
    if "com.google.gms.google-services" not in s:
        s2 = re.sub(r"(plugins\s*\{\n)", r'\1    id("com.google.gms.google-services") version "4.4.2" apply false\n', s, count=1)
        if s2 != s:
            s_path.write_text(s2, encoding="utf-8")
            cambios.append(str(s_path))

# ------------------------------------------------------------ gitignore
gi = android / ".gitignore"
lineas = gi.read_text(encoding="utf-8").splitlines() if gi.exists() else []
faltan = [x for x in ("key.properties", "**/*.jks", "**/*.keystore", "app/google-services.json") if x not in lineas]
if faltan:
    gi.write_text("\n".join(lineas + faltan) + "\n", encoding="utf-8")
    cambios.append(str(gi))

print("Sin cambios: ya estaba listo." if not cambios else "Actualizado:\n  " + "\n  ".join(cambios))
