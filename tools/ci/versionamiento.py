#!/usr/bin/env python3
"""Comprueba la matriz de versionamiento (requisito 11 del profesor).

Uso: python3 tools/ci/versionamiento.py [--rama refs/heads/release/1.2.0]

- pubspec.yaml usa SemVer `MAYOR.MENOR.PARCHE+build`.
- La versión aparece en docs/versionamiento.md (matriz de versiones).
- En una rama release/x.y.z, la versión del pubspec es x.y.z.
Escribe `app_version=x.y.z` en $GITHUB_OUTPUT para --dart-define=APP_VERSION.
"""
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "src/mobile/nexo_app/pubspec.yaml"
MATRIZ = ROOT / "docs/versionamiento.md"

rama = ""
if "--rama" in sys.argv:
    rama = sys.argv[sys.argv.index("--rama") + 1]
rama = rama or os.environ.get("GITHUB_REF", "")

m = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", PUBSPEC.read_text(encoding="utf-8"), re.M)
if not m:
    print("::error::pubspec.yaml debe tener version: MAYOR.MENOR.PARCHE+build (SemVer).")
    sys.exit(1)
version = ".".join(m.groups()[:3])
build = int(m.group(4))

fallas = []
if not MATRIZ.exists():
    fallas.append("Falta docs/versionamiento.md (matriz de versiones).")
else:
    filas = re.findall(r"^\|\s*`?(\d+\.\d+\.\d+)`?\s*\|", MATRIZ.read_text(encoding="utf-8"), re.M)
    if version not in filas:
        fallas.append(f"La versión {version} del pubspec no está en la matriz docs/versionamiento.md.")

r = re.match(r"refs/heads/release/(.+)$", rama)
if r and r.group(1) != version:
    fallas.append(f"La rama release/{r.group(1)} no coincide con la versión {version} del pubspec.")

for f in fallas:
    print(f"::error::{f}")
if fallas:
    sys.exit(1)

salida = os.environ.get("GITHUB_OUTPUT")
if salida:
    with open(salida, "a", encoding="utf-8") as fh:
        fh.write(f"app_version={version}\n")
print(f"VERSION-OK: {version}+{build} en la matriz.")
