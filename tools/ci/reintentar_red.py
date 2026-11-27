#!/usr/bin/env python3
"""Ejecuta una compilación y la repite solo si falló al descargar dependencias (spec 047).

Uso: python3 tools/ci/reintentar_red.py -- flutter build apk --debug
Un error de compilación o de configuración no se reintenta: falla al primer intento.
"""
import re
import subprocess
import sys
import time

ESPERAS = (30, 90)  # segundos antes del segundo y del tercer intento
FALLO_DE_RED = re.compile(
    r"status code (429|50[0-4])|Too Many Requests|error while downloading artifacts"
    r"|Could not (GET|HEAD) 'https?://[^']+'.*(timed out|reset|refused)"
    r"|Read timed out|Connection reset|Connect timed out",
    re.I,
)


def ejecutar(orden):
    """Muestra la salida en vivo y devuelve (código, hubo fallo de red)."""
    red = False
    with subprocess.Popen(orden, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                          encoding="utf-8", errors="replace") as proceso:
        for linea in proceso.stdout:
            sys.stdout.write(linea)
            sys.stdout.flush()
            red = red or bool(FALLO_DE_RED.search(linea))
    return proceso.returncode, red


def main(argumentos, pausa=time.sleep):
    orden = argumentos[1:] if argumentos[:1] == ["--"] else argumentos
    if not orden:
        print("Falta la orden a ejecutar.")
        return 2
    for intento in range(1, len(ESPERAS) + 2):
        codigo, red = ejecutar(orden)
        if codigo == 0 or not red or intento > len(ESPERAS):
            return codigo
        espera = ESPERAS[intento - 1]
        print(f"::warning::Fallo de red al descargar dependencias; intento {intento + 1} en {espera} s.", flush=True)
        pausa(espera)
    return codigo


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
