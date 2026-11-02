# TAREAS — 018-catalogo-seleccion

[Spec](spec.md), [plan](plan.md). Todo pendiente; diseño no es producto.

- [ ] T-006 →FR-090,NFR-090. Refinar fuente/actor/precondiciones/contrato. Acepta: AC-090 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: fuentes/dependencias de spec.
- [ ] T-020 →FR-100,NFR-100. Precisar escenario propio. Acepta: AC-100 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-006.
- [ ] T-001 →FR-001,FR-002,FR-003,NFR-002. Cerrar Ready con decisiones y revisión humana. Acepta: AC-090 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-006, T-020.
- [ ] T-002 →FR-001,FR-002,FR-003,NFR-003. Concretar cambio y archivos al encargar. Acepta: AC-001, AC-002, AC-003 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-001 y encargo correspondiente.
- [ ] T-010 →FR-001,NFR-001. Consumir categorías activas en alta, filtros y publicación con caché versionada. Acepta: AC-001 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-002.
- [ ] T-011 →FR-002,NFR-001. No invocar PUT admin; categoría obsoleta exige refresco sin perder borrador. Acepta: AC-002 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-002.
- [ ] T-012 →FR-003,NFR-003. Integrar/reintentar/recuperar. Acepta: AC-003 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-002.
- [ ] T-021 →FR-100,NFR-100. Catálogo caído permite lectura marcada; categoría retirada no se envía como válida. Acepta: AC-100 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-002, T-020.
- [ ] T-003 →NFR-003. Integrar consumidor/provider o entregable operativo. Acepta: AC-001, AC-002, AC-003 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-010, T-011, T-012, T-021, T-214.
- [ ] T-004 →NFR-001,NFR-100. Verificar aislamiento y permiso. Acepta: AC-002, AC-100 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-003.
- [ ] T-007 →FR-090,NFR-090,NFR-002. Comprobar refinamiento. Acepta: AC-090 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-004.
- [ ] T-005 →NFR-002,NFR-003. Conciliar evidencia/Memoria y revisión. Acepta: AC-001, AC-002, AC-003, AC-090, AC-100 documentados y después comprobados con evidencia apropiada, sin éxito ficticio. Depende de: T-007.

## Historias de operación — refinamiento e implementación futura

- [ ] T-214 →FR-214,NFR-001,NFR-003. Diseñar e integrar intención consumidora de EP-014; enlazar revisión de contrato, mapear resultado/error/sesión/red y cancelar respuesta obsoleta al cambiar de cuenta. Acepta: AC-214: EP-014: la intención muestra pendiente/confirmado o resultado/vacío según método, valida permiso/estado por respuesta API y presenta error recuperable; Excluir altas inactivas; caché público 24 h La UI refleja la regla del servidor, no la sustituye. Previsto en línea base; contrato formal y aceptación pendientes. Depende de: T-002 y contrato formal/decisiones de esta historia; no exige construir todo el dominio.
