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
          y que fallan por la razón correcta
   GREEN  el código mínimo para pasarlos
   REFACTOR con los tests en verde

5. Verifica: <comando de test completo> y <comando de build>.
   La suite completa, no solo tus tests.

6. Commitea SOLO los archivos que la tarea declara. Nunca `git add -A`.
   Mensaje: "T-003: <título>" + qué hiciste + "Plan: <slug> · Tarea: T-003"

7. Marca `estado: in_review` en tu archivo de tarea y agrega a la bitácora
   los tests que pasaron y el sha del commit.

8. NO apruebes tu propio trabajo. Termina aquí y reporta.

Restricciones duras:
- Solo edita los archivos que TU tarea declara. Ningún otro.
- Solo escribe en docs/plans/<slug>/tasks/T-003.md. Ningún otro archivo del plan.
- Si necesitas tocar un archivo no declarado, PARA y reporta: el plan tiene una
  colisión que la matriz no vio, y eso se arregla en el plan, no improvisando.
- Si un test no pasa y no es obvio por qué, PARA y reporta.
- Si la tarea toca auth, permisos, pagos, migraciones destructivas, borrado de datos
  o algo no reversible con `git revert`, PARA y pide autorización.
```

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
