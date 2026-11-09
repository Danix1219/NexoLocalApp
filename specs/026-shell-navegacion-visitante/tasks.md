# Tareas — 026-shell-navegacion-visitante

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/app/router.dart`, `lib/features/shell/shell_page.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001. La barra inferior muestra Inicio, Buscar, Publicar, Mensajes y Cuenta con la pestaña activa resaltada y altura propia (no ocupa la pantalla). Acepta: AC-001 comprobado por `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-002, AC-003. Sin sesión, «Explorar sin cuenta» abre Inicio en modo visitante; el router permite Inicio y Buscar y muestra puerta en Publicar, Mensajes y Cuenta. Acepta: AC-002, AC-003 comprobado por `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-004. Toda acción privada (contactar, guardar, comparar, recomendar, avisos) abre la hoja de puerta con «Crear cuenta gratis» e «Iniciar sesión»; al elegir, el visitante sale del modo y llega al flujo de spec 004. Acepta: AC-004 comprobado por `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-005. El globo de Mensajes refleja `totalUnread` del rol activo y se refresca cada 30 s y al volver de un chat. Acepta: AC-005 comprobado por `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-006. Las redirecciones respetan la sesión: con sesión no se ve el flujo de entrada; sin sesión ni visitante no se ve el shell. Acepta: AC-006 comprobado por `test/integration/sesion_test.dart`, `test/security/enlaces_profundos_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: reglas cubiertas por las de integración. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/sesion_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/enlaces_profundos_test.dart`, `test/security/privacidad_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.
