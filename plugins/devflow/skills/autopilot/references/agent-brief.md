# Brief para cada agente

El orquestador asigna la tarea **por nombre**. El agente nunca elige.

---

## Brief (subagente en la misma sesión — el caso normal)

```
Eres el agente <A1>. Tu tarea asignada es <T-003> del plan <slug>.
No tomes ninguna otra tarea. Si terminas, reporta y para.

1. Lee docs/plans/<slug>/tasks/T-003.md completo.

2. Cambia su frontmatter a `estado: in_progress` y agrega a la bitácora:
   `- <fecha ISO> A1 tomó la tarea`

3. Implementa con TDD estricto:
   RED    escribe los tests listados en la tarea, córrelos, verifica que FALLAN
          y que fallan por la razón correcta
   GREEN  el código mínimo para pasarlos
   REFACTOR con los tests en verde

4. Verifica: <comando de test completo> y <comando de build>.
   La suite completa, no solo tus tests.

5. Commitea SOLO los archivos que la tarea declara. Nunca `git add -A`.
   Mensaje: "T-003: <título>" + qué hiciste + "Plan: <slug> · Tarea: T-003"

6. Marca `estado: in_review` en tu archivo de tarea y agrega a la bitácora
   los tests que pasaron y el sha del commit.

7. NO apruebes tu propio trabajo. Termina aquí y reporta.

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

## Worktrees (paralelismo real, terminales separadas)

Cuando quieras agentes de verdad independientes, o mezclar claude-code con codex
escribiendo código al mismo tiempo.

```bash
git worktree add ../$(basename $PWD)-A2 -b devflow/<slug>/A2
```

Aquí **no hay orquestador automático**: tú repartes. Abre cada terminal y dale a cada
agente su tarea por nombre, del conjunto listo. La regla de archivos exclusivos es lo que
hace que esto sea seguro sin coordinación entre terminales.

Los archivos de tarea viven en el repo principal. Desde un worktree se leen y escriben por
ruta relativa normal si `docs/plans/` está commiteado — pero entonces cada worktree tiene
su propia copia y se desincronizan. Dos opciones:

- **Recomendada:** el agente del worktree reporta al terminar, y el orquestador (tú, o el
  agente del repo principal) actualiza el archivo de tarea. Una sola copia cambia.
- Alternativa: cada agente edita el archivo de tarea en el repo principal por ruta
  absoluta, no en su worktree.

### Orden de merge

Las ramas se integran **en orden de dependencia**, no de terminación:

```bash
git checkout main
git merge --no-ff devflow/<slug>/A2      # solo tras APPROVED
<comando de test>                         # la suite debe quedar verde tras cada merge
```

Si un merge rompe la suite, el arreglo es una tarea nueva, no un parche silencioso.

### Limpieza

```bash
git worktree remove ../<repo>-A2 && git branch -d devflow/<slug>/A2 && git worktree prune
```

---

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
