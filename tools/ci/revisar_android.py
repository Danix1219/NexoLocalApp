#!/usr/bin/env python3
"""Revisión de seguridad de la configuración Android (spec 046/048).

Uso: python3 tools/ci/revisar_android.py <carpeta-de-la-app>
Para corregir lo que reporta: python3 tools/android/preparar_android.py <carpeta-de-la-app>
Falla si el APK/AAB de release puede filtrar datos o hablar en claro.
"""
import pathlib
import re
import sys

app = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "src/mobile/nexo_app")
manifest = app / "android/app/src/main/AndroidManifest.xml"
fallas, avisos = [], []

if not manifest.exists():
    print(f"No existe {manifest}: sube la carpeta android/ de la app.")
    sys.exit(1)
m = manifest.read_text(encoding="utf-8")

def attr(name):
    r = re.search(rf'android:{name}\s*=\s*"([^"]+)"', m)
    return r.group(1) if r else None

if attr("usesCleartextTraffic") == "true":
    fallas.append('android:usesCleartextTraffic="true" en el manifiesto principal (solo HTTPS en release).')
if attr("allowBackup") != "false":
    fallas.append('Falta android:allowBackup="false": el respaldo copiaría tokens y caché de la cuenta.')
if attr("debuggable") == "true":
    fallas.append('android:debuggable="true" en el manifiesto principal.')
if "android.permission.INTERNET" not in m:
    fallas.append("Falta el permiso INTERNET (el APK de release no podría llamar al backend).")
for p in ("ACCESS_COARSE_LOCATION", "ACCESS_FINE_LOCATION"):
    if f"android.permission.{p}" not in m:
        avisos.append(f"Falta {p}: «Usar mi ubicación» no funcionará.")
if "android.permission.POST_NOTIFICATIONS" not in m:
    fallas.append("Falta POST_NOTIFICATIONS: en Android 13+ no llegarían los avisos push (requisito 16).")
if "<queries>" not in m:
    avisos.append("Falta <queries> para abrir mapas y enlaces (url_launcher en Android 11+).")
for p in ("READ_CONTACTS", "READ_SMS", "RECORD_AUDIO", "READ_CALL_LOG", "ACCESS_BACKGROUND_LOCATION"):
    if f"android.permission.{p}" in m:
        fallas.append(f"Permiso {p} no lo necesita la app (datos mínimos, constitución §2).")

gradle = app / "android/app/build.gradle.kts"
if gradle.exists():
    g = gradle.read_text(encoding="utf-8")
    if re.search(r"isDebuggable\s*=\s*true", g):
        fallas.append("isDebuggable = true en build.gradle.kts.")
    if "minSdk" in g and re.search(r"minSdk\s*=\s*(1\d|2[0-3])\b", g):
        fallas.append("minSdk menor a 24 (lo exige la proteccion automatica de Google Play).")
    if "google-services" not in g:
        avisos.append("build.gradle.kts no aplica Google Services: sin push (corre tools/android/preparar_android.py).")
else:
    avisos.append("No se encontró android/app/build.gradle.kts.")

for a in avisos:
    print(f"::warning::{a}")
for f in fallas:
    print(f"::error::{f}")
if fallas:
    sys.exit(1)
print("ANDROID-OK: manifiesto y build sin hallazgos bloqueantes.")
