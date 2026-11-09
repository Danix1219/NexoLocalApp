#!/usr/bin/env python3
"""Compuerta final 'CI · todo verde' (spec 047).

Lee el resultado de cada job (variable RESULTADOS = toJSON(needs)) y falla si
alguno no terminó en success o skipped. Un job se salta solo cuando su
condición lo excluye (p. ej. revisión de dependencias fuera de un PR).
"""
import json
import os
import sys

resultados = json.loads(os.environ.get("RESULTADOS", "{}"))
if not resultados:
    print("Sin resultados de jobs: la compuerta no puede aprobar.")
    sys.exit(1)
malos = {k: v.get("result") for k, v in resultados.items() if v.get("result") not in ("success", "skipped")}
for k in sorted(resultados):
    estado = resultados[k].get("result")
    print(f"{'OK ' if k not in malos else 'XX '} {k}: {estado}")
if malos:
    print(f"\n{len(malos)} job(s) sin pasar: " + ", ".join(sorted(malos)))
    sys.exit(1)
print(f"\nTodo verde: {len(resultados)} jobs.")
