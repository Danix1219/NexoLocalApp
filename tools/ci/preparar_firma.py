#!/usr/bin/env python3
"""Escribe android/key.properties y la llave de subida desde secretos (spec 048).

Uso (desde la carpeta de la app): python3 ../../../tools/ci/preparar_firma.py android
Lee KEYSTORE_B64, STORE_PASSWORD, KEY_ALIAS y KEY_PASSWORD del entorno.
Nunca imprime valores. El job borra ambos archivos al terminar.
"""
import base64
import os
import pathlib
import re
import sys

android = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "android")
faltan = [k for k in ("KEYSTORE_B64", "STORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD") if not os.environ.get(k)]
if faltan:
    print("::error::Faltan secretos de firma en el entorno 'firma': " + ", ".join(faltan))
    sys.exit(1)

gradle = (android / "app/build.gradle.kts").read_text(encoding="utf-8")
if "key.properties" not in gradle or not re.search(r'signingConfigs\s*\{[\s\S]*create\("release"\)', gradle):
    print("::error::android/app/build.gradle.kts no firma con key.properties. "
          "Aplica el bloque de docs/play-store.md (sección Firma).")
    sys.exit(1)

jks = android / "app/upload-keystore.jks"
jks.write_bytes(base64.b64decode(os.environ["KEYSTORE_B64"]))
(android / "key.properties").write_text(
    "storePassword={}\nkeyPassword={}\nkeyAlias={}\nstoreFile=upload-keystore.jks\n".format(
        os.environ["STORE_PASSWORD"], os.environ["KEY_PASSWORD"], os.environ["KEY_ALIAS"]),
    encoding="utf-8",
)
os.chmod(android / "key.properties", 0o600)
os.chmod(jks, 0o600)
print("FIRMA-OK: key.properties y llave escritas (valores no mostrados).")
