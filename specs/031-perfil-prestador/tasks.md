# Tareas — 031-perfil-prestador

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/provider/provider_page.dart`, `lib/features/common/actions.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. El encabezado muestra nombre, tipo (negocio u oficio), categorías, insignias con su significado y datos rápidos (atención, estado, visita, precio desde). Acepta: AC-001 comprobado por `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002. Información muestra el horario de la semana con el día de hoy resaltado, precios con «Desde»/«A cotizar», condiciones y la zona en mapa; lo no publicado dice «No publicó». Acepta: AC-002 comprobado por `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-003. Opiniones muestra el resumen (recomiendan de total) y cada opinión; sin opiniones en perfil nuevo aclara que no es negativo. Acepta: AC-003 comprobado por `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-004. Con local, «Cómo llegar» abre la app de mapas en la ubicación del local. Acepta: AC-004 comprobado por `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-005. El perfil propio muestra «Mi perfil», «Completa tu perfil» y botones de edición por sección en lugar de Contactar. Acepta: AC-005 comprobado por `test/unit/models_test.dart`, `test/integration/http_perfil_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/models_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_perfil_test.dart`, `test/integration/http_pedidos_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: controles transversales de `test/security` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
