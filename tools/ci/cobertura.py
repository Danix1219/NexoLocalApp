#!/usr/bin/env python3
"""Junta los .lcov de cada job de prueba y aplica el umbral (spec 046/047).

La constitución (§8) fija 45 % como base docente. El umbral se mide sobre la
capa lógica (datos, red, sesión, validación, configuración), que es la que
prueban las tres capas; la cobertura total se informa para seguimiento.
"""
import argparse
import pathlib
import sys

LOGICA = (
    "lib/data/", "lib/core/network/", "lib/core/auth/", "lib/core/validation.dart", "lib/app/env.dart",
    # 0.3.0: caché/cola, decisión de ML, redacción para la IA y push (specs 049-051)
    "lib/core/local/local_store.dart", "lib/core/local/offline_interceptor.dart", "lib/core/local/sync_controller.dart",
    "lib/features/intelligence/category_suggester.dart", "lib/features/intelligence/redact.dart",
    "lib/features/push/push_controller.dart", "lib/features/push/push_gateway.dart",
)


def leer(carpeta):
    lineas = {}
    for f in pathlib.Path(carpeta).rglob("*.lcov"):
        actual = None
        for raw in f.read_text(encoding="utf-8", errors="replace").splitlines():
            if raw.startswith("SF:"):
                actual = raw[3:].replace("\\", "/")
                i = actual.find("lib/")
                actual = actual[i:] if i >= 0 else actual
                lineas.setdefault(actual, {})
            elif raw.startswith("DA:") and actual:
                num, hits = raw[3:].split(",")[:2]
                prev = lineas[actual].get(int(num), 0)
                lineas[actual][int(num)] = max(prev, int(hits))
    return lineas


def porcentaje(lineas, filtro=None):
    total = cubiertas = 0
    for archivo, ls in lineas.items():
        if filtro and not archivo.startswith(filtro):
            continue
        total += len(ls)
        cubiertas += sum(1 for h in ls.values() if h > 0)
    return (100.0 * cubiertas / total if total else 0.0), cubiertas, total


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("carpeta")
    ap.add_argument("--min", type=float, default=45.0)
    a = ap.parse_args()
    lineas = leer(a.carpeta)
    if not lineas:
        print("No llegó ningún archivo de cobertura.")
        sys.exit(1)
    pl, cl, tl = porcentaje(lineas, LOGICA)
    pt, ct, tt = porcentaje(lineas)
    print("## Cobertura combinada\n")
    print("| Alcance | Líneas cubiertas | Cobertura |")
    print("|---|---|---|")
    print(f"| Capa lógica (umbral {a.min:.0f} %) | {cl}/{tl} | **{pl:.1f} %** |")
    print(f"| Toda la app (seguimiento) | {ct}/{tt} | {pt:.1f} % |")
    print()
    for archivo in sorted(lineas):
        if archivo.startswith(LOGICA):
            p, c, t = porcentaje({archivo: lineas[archivo]})
            print(f"- `{archivo}`: {p:.0f} % ({c}/{t})")
    if pl < a.min:
        print(f"\n**Falla:** la capa lógica tiene {pl:.1f} % y el mínimo es {a.min:.0f} %.")
        sys.exit(1)


if __name__ == "__main__":
    main()
