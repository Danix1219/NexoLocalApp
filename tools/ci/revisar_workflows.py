#!/usr/bin/env python3
"""Workflows seguros (spec 046/047): acciones de terceros fijadas por SHA,
permisos mínimos declarados y sin pull_request_target que ejecute código del PR."""
import pathlib
import re
import sys

fallas = []
for wf in sorted(pathlib.Path(".github").rglob("*.y*ml")):
    t = wf.read_text(encoding="utf-8")
    for m in re.finditer(r"uses:\s*([^\s#]+)", t):
        ref = m.group(1)
        if ref.startswith("./") or ref.startswith("docker://"):
            continue
        if not re.search(r"@[0-9a-f]{40}$", ref):
            fallas.append(f"{wf}: {ref} no está fijada por SHA de 40 caracteres.")
    if wf.parent.name == "workflows":
        if not re.search(r"(?m)^permissions:", t):
            fallas.append(f"{wf}: falta 'permissions:' global (mínimo privilegio).")
        if re.search(r"(?m)^\s*contents:\s*write", t):
            fallas.append(f"{wf}: pide contents: write.")
        if "pull_request_target" in t and "github.event.pull_request.head" in t:
            fallas.append(f"{wf}: pull_request_target con código del PR.")
for f in fallas:
    print(f"::error::{f}")
if fallas:
    sys.exit(1)
print("WORKFLOWS-OK")
