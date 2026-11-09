# Plan — 048-publicacion-play-store

Spec origen: [spec](spec.md). Rama: `feature/<CLAVE-JIRA>-048-publicacion-play-store`. Tareas: [tasks](tasks.md). Gates: [checklist](checklist.md).

## 1. Árbol objetivo (archivos a crear/modificar)

```text
src/mobile/nexo_app/
../../../.github/workflows/app-ci.yml
../../../tools/ci/preparar_firma.py
../../../docs/play-store.md
../../../infra/github/main.tf
```

## 2. Contratos (rutas, config, env)

- — `Google Play Developer API (acción upload-google-play)` — grupo `—`: subida.
- Modo por grupo: `auto` intenta el backend y usa la maqueta si el endpoint no está disponible ([045](../045-resiliencia-consumo-api/spec.md)).

## 3. Cambios por archivo (qué y por qué)

| Archivo | Qué hace | Requisitos |
|---|---|---|
| `.github/workflows/app-ci.yml` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `tools/ci/preparar_firma.py` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `docs/play-store.md` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |
| `infra/github/main.tf` | Ver spec. | FR-001, FR-002, FR-003, FR-004 |

Decisiones de diseño:

- Play App Signing de Google con llave de subida propia.
- Estado `draft` por variable hasta publicar la ficha.

## 4. Tests por requisito FR/NFR

| Requisito | Capa | Archivo / control | Job del pipeline |
|---|---|---|---|
| FR-001 | Pipeline | `Construir · AAB firmado` | Construir · AAB firmado |
| FR-001 | Pipeline | `Seguridad · AndroidManifest y build` | Seguridad · AndroidManifest y build |
| FR-002 | Pipeline | `Construir · AAB firmado` | Construir · AAB firmado |
| FR-002 | Pipeline | `Seguridad · AndroidManifest y build` | Seguridad · AndroidManifest y build |
| FR-003 | Pipeline | `Construir · AAB firmado` | Construir · AAB firmado |
| FR-003 | Pipeline | `Seguridad · AndroidManifest y build` | Seguridad · AndroidManifest y build |
| FR-004 | Pipeline | `Construir · AAB firmado` | Construir · AAB firmado |
| FR-004 | Pipeline | `Seguridad · AndroidManifest y build` | Seguridad · AndroidManifest y build |
| NFR-001 | Seguridad | gitleaks, OSV, AndroidManifest, workflows | Seguridad · (herramientas) |
| NFR-002 | Integración | `test/integration/resiliencia_test.dart` | Integración · resiliencia |
| NFR-003 | Manual | Revisión en Android con TalkBack y sin red | Evidencia en checklist |
| NFR-004 | Pipeline | `.github/workflows/app-ci.yml` | CI · todo verde |

## 5. Gates

Calidad · formato → Calidad · análisis estático → «Construir · AAB firmado» · «Seguridad · AndroidManifest y build» → Calidad · cobertura combinada → Construir · APK de prueba → CI · todo verde. Detalle del grafo: [pipeline](../../docs/pipeline.md).

## 6. Riesgos y deudas documentadas

- Perder la llave de subida obliga a pedir reinicio en Play Console; guardar respaldo fuera del repositorio.
- La primera versión debe subirse a mano en Play Console (la API no crea apps).

## 7. Orden de implementación

T-001 → T-010 → T-011 → T-012 → T-013 → T-002 → T-003 → T-004 → T-005 → T-006. El código de las tareas de la fase B ya existe; su cierre depende de la evidencia de la fase C.
