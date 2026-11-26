# Checklist — 040-mensajeria-chat

## DoD
- [ ] Spec, plan y tareas conciliados con el código (T-001).
- [ ] Jobs del plan en verde en el PR: «Unidad · fake-messages», «Integración · http-mensajes», «CI · todo verde» (T-002, T-003, T-004).
- [ ] Revisión en Android de estados y accesibilidad (T-005).
- [ ] Memoria y docs vivos actualizados (T-006).

## Evidencia por criterio
| Criterio | Cómo se comprueba | Resultado |
|---|---|---|
| AC-001 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` | pendiente |
| AC-002 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` | pendiente |
| AC-003 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` | pendiente |
| AC-004 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` | pendiente |
| AC-005 | `test/unit/fake_messages_test.dart`, `test/integration/http_mensajes_test.dart` | pendiente |
| AC-901 | pipeline | pendiente |
| AC-902 | pipeline | pendiente |
| AC-903 | dispositivo | pendiente |
| AC-904 | pipeline | pendiente |

## Aprobación
- [ ] Revisor real, fecha y alcance de firma.
- [ ] Borrador con evidencia solo si existe ejecución de producto.


### Correccion de pendientes 2026-11-19
Regresion 2026-11-19: widget con historial guardado de 36 mensajes, hueco antiguo y contador inicial uno. Confirma recent-34 y bandeja cero tras respuesta HTTP simulada. 67 pruebas aprobadas de diseno_maqueta, push_seguro y http_mensajes. Pruebas con dobles, recorrido real pendiente.

Cierre local 2026-11-19: flutter analyze sin incidencias; APK debug/live compilado e instalado -r en Xiaomi 096fd2cc784f, API ready 200 y reverse 5188/10000. Solo este telefono por instruccion del usuario. Recorrido humano de contador pendiente.

### Chat personalizable y gestion 2026-11-19
Estado: lista inversa en recientes, cinco fondos por cuenta/conversacion, edicion de texto propio y eliminacion para todos con confirmacion y marcas. API valida autoria y emite messageUpdated; editOf viaja cifrado. 87 pruebas Flutter aprobadas. Dos pruebas backend con Mongo real aprobadas antes del ajuste final de reintento; nueva comprobacion en curso. Recorrido fisico pendiente. No purga fisica de blobs ni copias ajenas.

Cierre validacion local 2026-11-19: flutter analyze sin incidencias; 87 pruebas Flutter aprobadas; 2 pruebas de integracion backend aprobadas en Release con MongoDB real, incluyendo reintento de revision antigua. No se reinicio API del usuario; debe recompilarla para cargar endpoints nuevos.

APK debug/live compilado e instalado -r en Xiaomi 096fd2cc784f el 2026-11-19; app abierta y reverse 5188/10000 restaurado. Solo dispositivo conectado por instruccion del usuario. Reinicio de API y recorrido humano pendientes.

Tema coordinado (FR/AC-CHAT-THEME): paleta por estilo aplicada a burbujas y audio; acceso en cabecera y opciones; comprobar contraste y selector en suite diseno_maqueta. Validacion fisica pendiente.
