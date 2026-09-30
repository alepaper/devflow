---
name: cross-review
argument-hint: "[T-00N]"
description: Reviews code written by a DIFFERENT agent across correctness, tests, security, design and readability, and returns a structured verdict (APPROVED / CHANGES_REQUESTED / BLOCKED). Supports an external reviewer CLI such as codex, or a Claude subagent with clean context. Use before any task is marked done, before merging anything, whenever the user says "revisa", "haz code review", "revisa esto con codex", or when a task sits in in_review. Never let the agent that wrote the code approve it.
---

# Review — Cross-Agent Code Review

## Overview

The agent that wrote the code cannot review it. It shares the blind spot that produced
the bug, and it's motivated to see its work as finished. A review is only worth something
when it comes from a different context — ideally a different model.

This skill produces a **structured verdict** that the autopilot can act on
programmatically. Prose feedback with no verdict line is not a review.

**Language:** talk to the user in Spanish. The review prompt and report are in Spanish
too, unless config says otherwise.

**Sin herramientas.** El revisor se invoca por shell y el veredicto se lee del texto.
El estado vive en el archivo de la tarea.

`$ARGUMENTS` may name the task to review. If it's empty, review everything in `in_review`.

## When to Use

- A task is in `in_review` status
- Before marking any task `done`
- Before merging a branch
- The user asks for a review, or asks to review with a specific tool

**Hard rule:** the reviewer identity must differ from the implementer identity. If
the same agent implemented and reviewed a task, that's a bug — stop.

## Choosing the reviewer

Read the `reviewer` field in `plan.md` frontmatter:

```yaml
reviewer: codex exec --skip-git-repo-check -   # o: subagente
```

| Mode | What it is | When |
|---|---|---|
| `external` | Another CLI, another model (codex, gemini, etc.) | **Preferred.** A different model catches what the writer's model structurally misses. |
| `subagent` | A Claude subagent with clean context and no implementation history | When no external CLI is available. Better than nothing, weaker than `external`. |

Never fall back to "review it yourself in the same context". If neither is available,
report that the task cannot be approved and leave it in `in_review`.

See `references/external-reviewers.md` for setup of codex and others.

## The Process

### 1. Assemble the evidence

The reviewer gets no conversation history — everything it needs must be in the prompt:

```bash
git diff <base>..HEAD -- <archivos de la tarea>    # el cambio
cat docs/plans/<slug>/breakdown/T-003.md               # criterios de aceptación
<comando de test>                                  # salida real de los tests
```

### 2. Build the review prompt

Write it to `docs/plans/<slug>/reviews/T-003-round-N-prompt.md`:

```markdown
Eres un ingeniero senior haciendo code review. NO escribiste este código.

## Tarea
<contenido de tasks/T-003.md: qué logra, criterios de aceptación, tests esperados>

## Diff
```diff
<git diff completo>
```

## Salida de los tests
```
<salida real, no un resumen>
```

## Qué evaluar

1. CORRECCIÓN — ¿hace lo que dicen los criterios? ¿Casos borde: null, vacío, cero,
   límites, errores? ¿Condiciones de carrera o estado inconsistente?
2. TESTS — ¿cada criterio de aceptación tiene un test? ¿Los tests prueban comportamiento
   o implementación? ¿Pasarían con una implementación vacía? ¿Se debilitó alguno
   (skip, assert borrado, try/except que traga)?
3. SEGURIDAD — ¿entrada validada en los bordes? ¿Secretos fuera del código y los logs?
   ¿Autorización verificada? ¿Consultas parametrizadas? ¿Se filtra información en los
   mensajes de error?
4. DISEÑO — ¿sigue los patrones del repo o inventa uno nuevo sin justificarlo?
   ¿Dependencias en la dirección correcta? ¿Sobre-ingeniería?
5. LEGIBILIDAD — ¿otro ingeniero lo entiende sin explicación? ¿Nombres claros?
   ¿Anidamiento razonable?

## Formato de salida OBLIGATORIO

Termina tu respuesta exactamente con este bloque:

VERDICT: APPROVED | CHANGES_REQUESTED | BLOCKED
BLOCKERS:
- <solo lo que impide aprobar; vacío si apruebas>
NITS:
- <opcional, no bloquea>

Usa CHANGES_REQUESTED solo por problemas reales de corrección, tests, seguridad o
diseño. Preferencias de estilo van en NITS y no bloquean.
Usa BLOCKED si el cambio toca algo irreversible o necesita una decisión humana.
```

### 3. Run it

```bash
codex exec --skip-git-repo-check - \
  < docs/plans/<slug>/reviews/T-003-round-1-prompt.md \
  | tee docs/plans/<slug>/reviews/T-003-round-1.md
```

Then read the output and find the `VERDICT:` line. If there isn't one, re-run once with
the format requirement repeated. If it fails twice, treat it as BLOCKED and escalate;
don't guess at what the reviewer meant.

### 4. Act on the verdict

**APPROVED** → set `estado: done` in `tasks/T-003.md`, add the verdict to its bitácora,
and notify (see the `autopilot` skill's notifications reference).
NITS are recorded in the task bitácora. They don't block, and they don't get silently
implemented either — if one matters, it becomes a task.

**CHANGES_REQUESTED** → set `estado: changes_requested` and write the blockers into the
task's bitácora. Back to the implementing agent. Fix, keep the tests green, return to `in_review`. The
reviewer sees the new diff on the next round.

**Three rounds is the ceiling.** A task bouncing three times is mis-specified, not badly
implemented. Stop and escalate to the user.

**BLOCKED** → status `blocked`, notify, stop. This is a human decision.

### 5. Reviewing as a subagent

When the reviewer is `subagente`, spawn a Task-tool agent with the same prompt and an explicit
instruction: *"No escribiste este código. No asumas buena intención en el diff. Verifica
los criterios uno por uno contra los tests."*

Give it the prompt file only. Not the conversation, not the implementation reasoning.
Context contamination is what makes self-review worthless.

## Severity — what actually blocks

| Blocks | Doesn't block |
|---|---|
| An acceptance criterion isn't met | Naming you'd have done differently |
| A criterion has no test | A missing comment |
| Tests would pass on an empty implementation | Formatting the linter doesn't flag |
| A test was skipped, weakened or deleted | A refactor you'd prefer |
| Unvalidated input at a trust boundary | A slightly different file layout |
| Secrets in code, logs or git | Micro-optimizations with no measurement |
| Missing authorization check | Test style preferences |
| SQL injection, XSS, path traversal | |
| Data loss or a destructive irreversible path | |

A reviewer that blocks on preferences trains everyone to ignore reviews. A reviewer that
approves untested criteria makes the whole gate theater.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Yo lo escribí pero lo reviso objetivamente" | You can't. You share the assumptions that produced it. That's why this gate exists. |
| "Es un cambio chiquito, no necesita revisión" | Small changes ship most production incidents. |
| "Los tests pasan, entonces está bien" | Tests pass on tests that test nothing. Check that they'd fail without the code. |
| "Bloqueo porque yo lo habría hecho distinto" | Preference goes in NITS. Blocking on taste kills the signal. |
| "Apruebo con comentarios menores para no frenar" | Then the comments never get addressed. Approve or request changes. |
| "Cuarta ronda y ya casi" | Three rounds means the task is wrong, not the code. Escalate. |

## Red Flags

- Implementer and reviewer are the same agent id
- A review that never produced a VERDICT line
- Approval of a task where an acceptance criterion has no test
- CHANGES_REQUESTED consisting only of style preferences
- The reviewer was given the implementation conversation as context
- A verdict of UNKNOWN treated as APPROVED
- More than three review rounds on one task
- Review notes that exist nowhere in the task's bitácora

## Verification

- [ ] The reviewer is a different agent from the implementer
- [ ] The review prompt contained the task criteria, the full diff and real test output
- [ ] A structured verdict was produced and parsed
- [ ] Every acceptance criterion was checked against a specific test
- [ ] Blockers are correctness/tests/security/design issues, not preferences
- [ ] The verdict was acted on: done, back to the implementer, or escalated
- [ ] The review report is saved under `docs/plans/<slug>/reviews/`
- [ ] The task's bitácora records the reviewer and the round count
