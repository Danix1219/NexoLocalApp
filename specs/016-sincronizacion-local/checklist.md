# Checklist — 016-sincronizacion-local

## DoD
- [ ] Allowlist, revisión de contratos, protección/retención y esquema/migración definidos.
- [ ] Requisitos, tareas y AC trazados; datos/cola aislados por cuenta.
- [ ] AC-001..006/090/100 verificados con tipo de evidencia correcto cuando exista producto.
- [ ] SQLite real, API real y dispositivo se distinguen de dobles.
- [ ] [CHECKLIST_PR.md](../../CHECKLIST_PR.md) y Memoria conciliados; sin secretos.

## Aprobación
- [ ] Revisor humano: por asignar. Fecha: pendiente.
- [ ] Borrador documental; no pruebas de producto ejecutadas.

## Integridad de cobertura 0.3.0

- [ ] Todos los FR/NFR de la spec aparecen en tareas y tabla de trazabilidad; cada AC tiene tarea real.
- [ ] T-006/T-007/T-020/T-021 existen; dependencias locales resueltas y sin ciclos.
- [ ] AC-100: Una respuesta que llega después de logout/cancelación/cambio de cuenta no repuebla caché privada ni inicia reenvío de sesión anterior.
- [ ] El revisor distingue cumplimiento documental de aceptación de producto; D01–D08 pertinentes y excepciones visibles.

## Funciones/obligaciones de fuente

- [ ] R09 Caché en tres niveles / AC-409: fuente y criterio conciliados; evidencia apropiada o pendiente explícito, sin datos inventados.

## Integridad de alcance 0.4.0

- [ ] Operaciones, funciones y obligaciones de esta spec tienen FR/tarea/AC y contrato/consumo correspondiente.
- [ ] No se implementan de nuevo operaciones delegadas a otra spec ni se invocan internas/admin desde Flutter.
- [ ] Estado opcional/complemento/pendiente no se convierte en cumplimiento obligatorio o aprobado por existir en catálogo.
