# Checklist — 050-notificaciones-push

## DoD
- [ ] Spec, plan y tareas conciliados con el código (T-001).
- [ ] Jobs del plan en verde en el PR: «Integración · push-controlador», «Unidad · push-mensajes», «Seguridad · push-seguro», «CI · todo verde» (T-002, T-003, T-004).
- [ ] Revisión en Android de estados y accesibilidad (T-005).
- [ ] Memoria y docs vivos actualizados (T-006).

## Evidencia por criterio
| Criterio | Cómo se comprueba | Resultado |
|---|---|---|
| AC-001 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-002 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-003 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-004 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-005 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-006 | `test/integration/push_controlador_test.dart`, `test/unit/push_mensajes_test.dart` | pendiente |
| AC-901 | pipeline | pendiente |
| AC-902 | pipeline | pendiente |
| AC-903 | dispositivo | pendiente |
| AC-904 | pipeline | pendiente |

## Aprobación
- [ ] Revisor real, fecha y alcance de firma.
- [ ] Borrador con evidencia solo si existe ejecución de producto.

### Evidencia local 2026-11-17
- flutter analyze: sin incidencias.
- 70 pruebas aprobadas: diseno_maqueta, push_seguro, push_controlador, enlaces_profundos y token_storage_isolation. Pruebas con widgets/dobles, no FCM productivo.
- QR de tarjeta renderizada en 320 y 390 px decodificado con ZXing: nexolocal://provider/profile-id; margen de cuatro modulos verificado.
- Pendiente: recibir mensaje con chat abierto/cerrado y escanear QR de un perfil real entre telefonos.

Chequeo documental check_sdd.ps1: fallo; enlaces legacy a carpetas hermanas ausentes y tareas de incrementos previos marcadas en fase documental. No equivale a fallo de pruebas de Flutter; no se declara SDD aprobado.
