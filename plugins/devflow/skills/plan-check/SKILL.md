---
name: plan-check
argument-hint: "[nombre-del-plan]"
description: Validates a plan with a DIFFERENT agent before it runs — checks that every task is self-executable without exploring, that the file matrix has no collisions, that the dependency graph is sound, and that acceptance criteria are verifiable. Returns a structured verdict. Use after /breakdown writes the tasks and before /autopilot, when the user says "valida el plan", "revisa las tareas", "¿esto se puede ejecutar solo?", or when inheriting a plan someone else wrote.
---

# Plan-check — Validation by a Different Agent

## Overview

`/spec-check` validates the requirement. `/cross-review` validates the code. Between them
sits the plan — **the thing `/autopilot` executes literally** — and nothing looked at it.

That gap matters most in exactly the case devflow is built for: an unattended run. A task
whose Contexto says "sigue las convenciones del proyecto" instead of citing a file gets
discovered at 2am, by an agent that will improvise rather than stop. The result may drift
from what you meant and nobody notices until morning.

The question this skill asks is narrow and checkable: **can an agent execute each task
without exploring the repository?**

**Language:** talk to the user in Spanish.

## Cuándo corre

| Situación | Qué pasa |
|---|---|
| `plan.md` declara un CLI externo y responde | **Obligatorio.** Se corre, no se pregunta. |
| No hay modelo externo | Se pregunta si correrlo con subagente. |

Nunca se salta solo. Sin modelo externo:

```
No hay un modelo externo configurado para validar el plan.

Puedo usar un subagente de Claude con contexto limpio: no escribió las tareas,
así que detecta contexto faltante — pero comparte los puntos ciegos del
planificador, así que encuentra menos que otro modelo.

  correr    lo valido con subagente
  saltar    arranco /autopilot sin validar el plan
```

Si se salta, queda en `plan.md`: `plan_check: omitido`.

## The hard rule

**The validator must not be the agent that wrote the plan.** Preferably a different model
(`codex`, `gemini`); otherwise a Claude subagent with clean context. Never "I'll re-read
it carefully" — that's the failure this exists to prevent.

## The Process

### 1. Assemble the input

- `plan.md` complete: matrix, waves, decisions, commands
- Every file in `tasks/`
- **A listing of the repository's file tree.** The validator needs it to tell whether a
  declared path actually exists.
- Nothing else. **No conversation, no spec.** If a task only makes sense with the spec at
  hand, that's the finding: the agent executing it won't have the spec either.

### 2. Build the prompt

Write it to `docs/plans/<slug>/plan-check-prompt.md`:

```markdown
Eres un ingeniero senior que va a ejecutar este plan con agentes automáticos, sin
supervisión, durante toda la noche. NO lo escribiste. Cada agente recibe UNA tarea y
nada más: ni el spec, ni la conversación, ni las otras tareas.

## El plan
<plan.md completo>

## Las tareas
<cada archivo de tasks/>

## Árbol del repositorio
<listado de archivos>

## Qué evaluar

1. AUTOEJECUTABILIDAD — por cada tarea: ¿un agente que solo tiene este archivo puede
   implementarla sin explorar el repositorio? ¿La sección Contexto trae rutas concretas,
   firmas reales y un archivo citado como patrón? Marca toda tarea que diga cosas como
   "sigue las convenciones", "los archivos de X" o "como en el resto del proyecto".
2. RUTAS — ¿los archivos que cada tarea declara existen en el árbol, o se van a crear?
   ¿Alguna ruta está mal escrita?
3. MATRIZ DE ARCHIVOS — recalcúlala desde las tareas. ¿Coincide con la del plan?
   ¿Hay algún archivo en dos tareas de la misma ola?
4. GRAFO — ¿toda `depende_de` apunta a una tarea que existe? ¿Hay ciclos? ¿Cae cada
   tarea en exactamente una ola?
5. CRITERIOS VERIFICABLES — ¿cada criterio de aceptación se puede comprobar
   objetivamente? ¿Cada uno tiene al menos un test listado?
6. DEPENDENCIAS FALTANTES — ¿alguna tarea consume algo (un tipo, una función, una tabla)
   que ninguna tarea anterior produce?
7. DEPENDENCIAS SOBRANTES — ¿alguna dependencia declarada no corresponde a nada real?
   Serializan el plan sin motivo.
8. TAMAÑO — ¿alguna tarea toca tantos archivos o tantas cosas distintas que debería ser
   dos?

## Lo que NO es tu trabajo

No propongas otra arquitectura. No opines sobre el enfoque técnico elegido. No reescribas
tareas. Señala qué impide que esto se ejecute solo.

## Formato de salida OBLIGATORIO

VERDICT: EJECUTABLE | HUECOS | BLOQUEADO
HUECOS:
- <tarea>: <categoría> → <qué falta exactamente>
MENORES:
- <lo que mejoraría el plan pero no impide ejecutarlo>

EJECUTABLE solo si cada tarea se puede implementar sin abrir nada que no esté declarado.
BLOQUEADO si el grafo tiene ciclos o la matriz tiene colisiones: eso no se ejecuta.
```

### 3. Run it and act on the verdict

```bash
codex exec --skip-git-repo-check - \
  < docs/plans/<slug>/plan-check-prompt.md \
  | tee docs/plans/<slug>/plan-check.md
```

**EJECUTABLE** → record `plan_check: EJECUTABLE` in `plan.md` and hand off to
`/autopilot`.

**HUECOS** → the normal outcome, and the cheap place to fix them. Unlike `/spec-check`,
most gaps here **you fix yourself**: a missing signature is something you read from the
code, not something only the user knows. Fill them, then re-run.

Only ask the user when a gap is a *fact* — a catalog, a business rule, a schema. Those
are the same ones `/spec` should have asked for, and finding one here means the spec was
thin.

**BLOQUEADO** → cycles or matrix collisions. Fix the plan in `/breakdown`; this isn't
executable at all.

### 4. Re-run after filling gaps

Cheap, and the second pass regularly catches something the fixes introduced. Two rounds is
normal. A third means `/breakdown` produced a weak plan — go back there rather than
patching task files one by one.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Escribí yo las tareas, sé que están completas" | You know what you meant. The agent only gets what you wrote. |
| "El agente ya buscará lo que falte" | That's the cost this exists to prevent, and at 2am it improvises instead of asking. |
| "Le paso también el spec al validador" | Then you're testing the spec, not the tasks. The executing agent won't have it either. |
| "Hay huecos pero son menores, arranco igual" | Each one becomes an improvised decision in an unattended run. |
| "Marcó 9 huecos, atiendo los 4 importantes" | You're re-deciding with the judgment that produced them. |

## Red Flags

- The plan's author validating it
- The spec or the conversation included in the prompt
- A task whose Contexto says "sigue las convenciones" passing as executable
- A declared path that doesn't exist and isn't created by any task
- Running `/autopilot` with `plan_check: HUECOS`
- Asking the user about gaps you could have resolved by reading the code

## Verification

- [ ] The validator was a different agent from the plan's author
- [ ] The prompt carried the plan, every task and the repo tree — no spec, no conversation
- [ ] A structured verdict came back and was parsed
- [ ] Every task was judged on whether it's executable without exploring
- [ ] Gaps that were readable from the code were filled, not asked about
- [ ] Factual gaps went back to the user
- [ ] The verdict is recorded in `plan.md`
- [ ] After filling gaps, validation ran again
