# Brief para cada agente

El orquestador asigna la tarea **por nombre**. El agente nunca elige.

```
Eres el agente <A1>. Tu tarea asignada es <T-003> del plan <slug>.
No tomes ninguna otra tarea. Si terminas, reporta y para.

1. Carga la skill `tdd` y síguela. Es obligatoria. El resumen del punto 4 es un
   recordatorio, no un reemplazo: las verificaciones que importan — que el RED falló
   por la razón correcta, que el test fallaría contra una implementación vacía, que
   nada se debilitó para llegar a verde — están en la skill, no aquí.

2. Lee docs/plans/<slug>/tasks/T-003.md completo.

3. Cambia su frontmatter a `estado: in_progress` y agrega a la bitácora:
   `- <fecha ISO> A1 tomó la tarea`

4. Implementa con TDD estricto:
   RED    escribe los tests listados en la tarea, córrelos, verifica que FALLAN
          y PEGA la línea del fallo en la bitácora antes de implementar nada
          y que fallan por la razón correcta
   GREEN  el código mínimo para pasarlos
   REFACTOR con los tests en verde

5. Verifica: <cmd_test>, <cmd_build> y <cmd_lint> si está configurado.
   La suite completa, no solo tus tests.
   Si el lint falla en archivos que tu tarea NO tocó, es preexistente: repórtalo,
   no lo arregles — sería trabajo no declarado y el revisor lo marcaría.
   Anota en la bitácora el resultado de los tres.

   Mira `documentar_codigo` en el plan. Si dice `si`, documenta lo que escribas.
   Si dice `no`, no agregues docstrings ni comentarios explicativos: el proyecto
   decidió que los tests documentan el comportamiento.

6. Commitea SOLO los archivos que la tarea declara. Nunca `git add -A`.
   Mensaje: "T-003: <título>" + qué hiciste + "Plan: <slug> · Tarea: T-003"

7. Marca `estado: in_review` en tu archivo de tarea y agrega a la bitácora
   los tests que pasaron y el sha del commit.

8. NO apruebes tu propio trabajo. Termina aquí.

9. Tu mensaje final debe ser EXACTAMENTE este bloque y nada más:

   TAREA: T-003
   ESTADO: in_review | blocked
   TESTS: <n> nuevos, suite completa <verde|roja>
   COMMIT: <sha corto>
   ARCHIVOS: <rutas separadas por coma>
   BLOQUEANTE: <una línea, o vacío>

   Sin resumen, sin razonamiento, sin repetir lo que hiciste. Todo eso ya quedó en
   la bitácora del archivo de tarea, que es donde se consulta. Tu mensaje final
   entra al contexto del orquestador: si escribes dos párrafos, los multiplica por
   cada tarea del plan.

Restricciones duras:
- Solo edita los archivos que TU tarea declara. Ningún otro.
- Solo escribe en docs/plans/<slug>/tasks/T-003.md. Ningún otro archivo del plan.
- Si necesitas tocar un archivo no declarado, PARA y reporta: el plan tiene una
  colisión que la matriz no vio, y eso se arregla en el plan, no improvisando.
- Si un test no pasa y no es obvio por qué, PARA y reporta.
- Si la tarea toca auth, permisos, pagos, migraciones destructivas, borrado de datos
  o algo no reversible con `git revert`, PARA y pide autorización.
```

## Por qué el reporte es tan corto

El mensaje final de cada subagente entra al contexto del orquestador y se queda ahí el
resto del plan. Un reporte en prosa son ~2000 tokens; el bloque de arriba son ~50. Con 15
tareas, la diferencia es ~30.000 tokens de contexto del orquestador — que además degradan
sus decisiones, no solo su costo.

El detalle no se pierde: vive en la bitácora del archivo de tarea, donde se consulta
cuando hace falta en vez de cargarse siempre.

La restricción de "solo escribe tu archivo de tarea" es lo que reemplaza al lock: si cada
agente escribe un archivo distinto, no hay nada que contender.

---

## Worktrees

Dos o más agentes en paralelo significa dos o más worktrees, uno por tarea. El montaje,
el orden de merge, la preparación con `cmd_setup` y qué hacer ante un conflicto están en
**[worktrees.md](worktrees.md)**.

## Reglas de colisión

1. **La matriz de archivos del plan es el contrato.** Un agente solo edita lo que su
   tarea declaró.
2. **Dos tareas en vuelo nunca comparten archivo.** Si comparten, el plan está mal: falta
   una dependencia o falta partir un archivo. Se arregla en el plan.
3. **Migraciones de base de datos son siempre secuenciales.**
4. **Un agente sin tarea asignada se detiene.** No busca trabajo.

---

## Cuántos agentes

| Forma del plan | Agentes útiles |
|---|---|
| Cadena lineal (cada tarea desbloquea la siguiente) | 1 |
| 2–3 slices verticales independientes | 2–3 |
| Muchas tareas tras un contrato común ya resuelto | 3–4 |

Con la regla de archivos exclusivos, los planes tienden a ser **más secuenciales** que
antes. Eso es el precio, y es consciente: un plan más lento que no se puede corromper.
Ante la duda, menos agentes.
