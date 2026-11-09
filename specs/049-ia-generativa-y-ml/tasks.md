# Tareas — 049-ia-generativa-y-ml

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/intelligence/category_suggester.dart`, `lib/features/intelligence/ml_kit_suggester.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. Al agregar la foto de una solicitud sin categoría elegida, el modelo de visión del teléfono sugiere una categoría con su porcentaje de confianza; la persona la usa o la ignora. Acepta: AC-001 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. El modelo se abstiene si la mejor categoría junta menos de 55 % o si la segunda está a menos de 15 puntos; también si el modelo falla. Acepta: AC-002 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. «Ayúdame a redactar» pide a EP-082 un borrador y lo muestra editable; el texto solo pasa al campo con «Usar este texto» y se publica con el botón de siempre. Acepta: AC-003 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. El texto que se envía al asistente no lleva teléfonos, correos, enlaces ni domicilios. Acepta: AC-004 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. Si el asistente no responde (sin señal, 404, 5xx o `assist.unavailable`) se informa y la persona sigue escribiendo; en release nunca se inventa un borrador. Acepta: AC-005 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.
- [ ] T-015 →FR-006; AC-006. Si la moderación rechaza el texto (`content.inappropriate`) se muestra un mensaje claro y no se publica. Acepta: AC-006 comprobado por `test/unit/ml_categoria_test.dart`, `test/integration/http_asistente_dispositivos_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/ml_categoria_test.dart`, `test/unit/asistente_y_dispositivos_fake_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014, T-015.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_asistente_dispositivos_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/ia_sin_datos_personales_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
