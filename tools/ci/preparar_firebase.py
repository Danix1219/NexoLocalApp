#!/usr/bin/env python3
"""Escribe android/app/google-services.json desde el secreto (spec 050).

Uso (desde la carpeta de la app): python3 ../../../tools/ci/preparar_firebase.py android
Lee GOOGLE_SERVICES_JSON y ANDROID_PACKAGE_NAME del entorno. Nunca imprime
el contenido. Sin este archivo el AAB de producción no tendría push, que es
requisito (16), así que falla.
"""
import json
import os
import pathlib
import sys

android = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "android")
raw = os.environ.get("GOOGLE_SERVICES_JSON", "").strip()
pkg = os.environ.get("ANDROID_PACKAGE_NAME", "").strip()
if not raw:
    print("::error::Falta el secreto GOOGLE_SERVICES_JSON en el entorno 'firma' (push de Firebase).")
    sys.exit(1)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("::error::GOOGLE_SERVICES_JSON no es un JSON válido.")
    sys.exit(1)
paquetes = {
    c.get("client_info", {}).get("android_client_info", {}).get("package_name")
    for c in data.get("client", [])
}
if pkg and pkg not in paquetes:
    print(f"::error::google-services.json no incluye la app {pkg}. Registra ese paquete en Firebase.")
    sys.exit(1)
gradle = (android / "app/build.gradle.kts")
if gradle.exists() and "google-services" not in gradle.read_text(encoding="utf-8"):
    print("::error::android/app/build.gradle.kts no aplica el plugin com.google.gms.google-services "
          "(corre tools/android/preparar_android.py).")
    sys.exit(1)
destino = android / "app/google-services.json"
destino.write_text(raw, encoding="utf-8")
os.chmod(destino, 0o600)
print("FIREBASE-OK: google-services.json escrito (contenido no mostrado).")
