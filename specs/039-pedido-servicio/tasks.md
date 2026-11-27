# Tareas — 039-pedido-servicio

Spec: [spec](spec.md). Plan: [plan](plan.md).

## Fase A — Preparación
- [ ] T-001 →NFR-004. Conciliar maqueta, contrato de `docs/endpoints` y código actual de `lib/features/orders/order_page.dart`, `lib/features/common/actions.dart`; registrar diferencias. Acepta: diferencias listadas en el checklist o «sin diferencias». Depende de: ninguna.

## Fase B — Implementación (código entregado; pendiente de verificar)
- [ ] T-010 →FR-001; AC-001, AC-002. Pedir envía `origin=direct` desde perfil o `origin=post` desde interesados, con `Idempotency-Key`; un activo duplicado muestra el error del servidor. Acepta: AC-001, AC-002 comprobado por `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart`. Depende de: T-001.
- [ ] T-011 →FR-002; AC-003. Las acciones visibles salen de `allowedActions`; cada una manda `If-Match` con la versión mostrada. Acepta: AC-003 comprobado por `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart`. Depende de: T-001.
- [ ] T-012 →FR-003; AC-004. Con un pedido pendiente, el prestador ve la zona aproximada y no la dirección ni el teléfono del cliente (H02). Acepta: AC-004 comprobado por `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart`. Depende de: T-001.
- [ ] T-013 →FR-004; AC-005. Un conflicto de versión (412/409) recarga el pedido y avisa sin aplicar la acción. Acepta: AC-005 comprobado por `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart`. Depende de: T-001.
- [ ] T-014 →FR-005; AC-006. Con el pedido resuelto, el cliente califica con estrellas desde la misma pantalla (spec 037). Acepta: AC-006 comprobado por `test/unit/fake_orders_test.dart`, `test/integration/http_pedidos_test.dart`. Depende de: T-001.

## Fase C — Pruebas y evidencia
- [ ] T-002 →NFR-004; AC-904. Pruebas de unidad: `test/unit/fake_orders_test.dart`. Acepta: jobs de Unidad en verde. Depende de: T-010, T-011, T-012, T-013, T-014.
- [ ] T-003 →NFR-002; AC-902. Integración: `test/integration/http_pedidos_test.dart` y resiliencia del grupo. Acepta: jobs de Integración en verde. Depende de: T-002.
- [ ] T-004 →NFR-001; AC-901. Seguridad: `test/security/privacidad_test.dart`, `test/security/cabeceras_y_subidas_test.dart` y herramientas (gitleaks, OSV, manifiesto, workflows). Acepta: jobs de Seguridad en verde. Depende de: T-002.
- [ ] T-005 →NFR-003; AC-903. Revisión en Android: carga, vacío, error, sin red y TalkBack. Acepta: capturas o notas en el checklist. Depende de: T-003.
- [ ] T-006 →NFR-004; AC-904. Registrar evidencia (enlace a la ejecución del PR) en checklist y Memoria. Acepta: «CI · todo verde» enlazado. Depende de: T-003, T-004, T-005.

## Verificación
No marcar hasta ejecutar el criterio y registrar evidencia en checklist/Memoria.

- [ ] T-050 →FR-006, FR-007, FR-008, FR-009; AC-006, AC-008. Correcciones de envío en la app con pruebas locales. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-051 →FR-010; AC-010. Nombre de la contraparte en la API con pruebas unitarias. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-052 →FR-006, FR-007, FR-008, FR-009, FR-010. Recorrido real cliente y prestador con la API reiniciada. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada.

- [ ] T-053 →FR-011, FR-012, FR-013. Implementado; 54/54 pruebas Engagement. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-054 →FR-011. Confirmar un pedido real a domicilio con credencial de Azure válida o llave local de desarrollo. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada.

- [ ] T-055 →FR-014: `actions.dart`. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-ORD-056 Configuración local; con ella, cifrado y guardado en una base temporal funcionaron. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada. Estado: implementada; aceptación pendiente.
- [ ] T-057 →FR-014. Enviar un pedido real desde el teléfono tras reiniciar la API. Acepta: el comportamiento de su requisito, comprobado con la evidencia indicada.
