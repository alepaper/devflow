---
name: breakdown
argument-hint: "[plan] — vacío para elegir entre los specs aprobados"
description: Breaks an approved spec into small tasks whose file sets never overlap, so two tasks can never collide. Any shared file becomes a dependency instead. Produces one markdown file per task with dependencies, acceptance criteria and declared files, in Linear or under docs/plans/<plan>/. Use whenever the user says "planea", "divide esto en tareas", "arma el plan", "¿cómo lo partimos?", right after a spec is approved, or before running /autopilot. Always run this before any implementation begins.
---

# Plan — Task Breakdown by File Exclusivity

## Overview

One rule carries this entire skill:

> **Two tasks must never need the same file. If they do, that's a dependency.**

Everything else follows. No two agents can collide, because no two parallel tasks touch
the same bytes. Parallelism stops being something you hope works and becomes something
the plan structurally guarantees.

The cost is real and you should state it openly: a file touched by five tasks serializes
all five. Some plans will have stretches where only one agent can work. That's the trade
— a slower plan that cannot corrupt itself, with nothing to install.

**Language:** talk to the user and write documents in Spanish.

**No scripts, no state engine.** The task files *are* the state. Each task file is
written by exactly one agent, so nothing is ever contended.

`$ARGUMENTS` may name a plan slug. If it's empty, run Step 0 and let the user choose.

## When to Use

- A spec exists at `docs/plans/<slug>/spec.md` with `estado: aprobado`
- The user asks to plan, break down, or estimate work
- Before `/autopilot`, always

**Hard precondition:** no approved spec → stop and run `/spec`. A README or a chat
message is not a spec.

If the spec's frontmatter shows `spec_check: HUECOS` or an empty `validado_con`, say so
before planning. Planning around an unvalidated spec turns its ambiguities into tasks,
and a task built on an ambiguity gets built twice.

## The Process

### Step 0 — Choose which spec or specs to plan

Skip this only when `$ARGUMENTS` names a slug, or when exactly one approved spec exists
and it has no plan yet.

Scan `docs/plans/*/spec.md` and show everything you found. Don't pick silently — the
user may have written three specs and want only one of them planned now.

```
Encontré 4 specs en docs/plans/:

  #  Plan                        Estado     Validación      Plan
  1  recuperacion-de-contrasena  aprobado   spec-check ✔    —
  2  portal-ds                   aprobado   sin validar     —
  3  notificaciones-push         aprobado   spec-check ✔    ya planeado (7 tareas)
  4  reportes-mensuales          borrador   —               —

¿Cuál planeo? Puedes decirme un número, varios (1,2), o "todos".
  · #3 ya tiene plan: replanearlo reemplaza sus tareas abiertas.
  · #4 sigue en borrador, no se puede planear todavía.
```

Show, per spec: slug, `estado`, `validado_con` / `spec_check`, and whether `plan.md` or
`tasks/` already exist.

Rules for what's selectable:

- **`estado: borrador`** → not plannable. Say so and point at `/spec` to finish it.
- **`spec_check: HUECOS` or empty `validado_con`** → plannable, but warn before starting.
  Planning around an unvalidated spec turns its ambiguities into tasks, and a task built
  on an ambiguity gets built twice.
- **Already has `plan.md` with open tasks** → never overwrite silently. Ask whether to
  replace it, extend it, or skip it.

If the user says "todos", read it as *all approved ones* and say which you excluded.

### Step 0b — When several specs are selected

Each spec keeps its own `docs/plans/<slug>/` folder. What changes is the matrix.

**Build one file matrix spanning every selected spec.** The whole guarantee is that two
tasks running in parallel never touch the same file, and two plans running in parallel
break it just as easily as two tasks in one plan. A per-plan matrix would miss exactly
the collisions that are hardest to debug, because they'd come from a plan the agent
isn't looking at.

A collision between plans is resolved the same three ways, plus a fourth:

- Split the file, extract an upstream task, or chain the tasks — as within one plan
- **Cross-plan dependency:** a task can depend on a task in another plan, written
  qualified: `depende_de: [portal-ds/T-003]`

Two things to surface to the user when they pick several:

- **Heavy overlap means they may be one spec.** If two specs collide on many files, say
  so. Two specs that rewrite the same module are usually one piece of work that got
  written down twice.
- **Wave numbering is global.** With several plans, "Ola 2" spans all of them. Say which
  plan each task belongs to in the wave map, or the numbers mislead.

If the user picks several and you can't build a clean combined matrix, plan them one at a
time and say plainly that running their autopilots concurrently isn't safe.

### Step 1 — Read-only reconnaissance
**Legacy layouts.** Before anything else, resolve the plan directory. Some projects were
created with `breakdown/` instead of `tasks/`, or `tasks.md` / `breakdown.md` instead of
`plan.md` — two over-broad command renames dragged artifact paths along with them.

Read `tasks/` first, falling back to `breakdown/`; `plan.md` first, falling back to
`tasks.md` then `breakdown.md`. If a legacy name is found, **migrate it with `git mv`
before working**, in its own commit, and tell the user in one line. If both the canonical
and the legacy name exist, stop and ask — merging them blindly can lose task files.

Procedure: `references/plan-layout.md`.


Read the spec and the code it touches. Note existing patterns, the documentation convention, the test setup, and **the
real commands**: how tests run, how the build runs, how lint runs (`cmd_lint`, which the
agents now run alongside tests and build), and **how a fresh
checkout is prepared** (`npm ci`, `uv sync`, `bundle install`). That last one is
`cmd_setup`, and `/autopilot` needs it to make a new worktree runnable — a worktree has
no `node_modules` and no `.env`. Note which ignored files the suite needs too. Record them in
`plan.md` frontmatter — the autopilot will need them and there is no config file anymore.

Write no code during planning.

**Explore here, once, so the implementers don't have to.** This is the single biggest
cost lever in the whole flow: with N agents, anything an implementer has to go find is
found N times, by the more numerous and usually cheaper models. You're the one agent
holding the whole picture — spend the exploration here.

For each task you're about to write, collect the concrete things an implementer would
otherwise search for:

| Recoge | En vez de que el agente busque |
|---|---|
| Rutas exactas de los archivos a crear o editar | "los archivos de auth" |
| Firmas reales que va a llamar o implementar | el agente leyendo tres archivos para deducirlas |
| El patrón vecino que debe seguir, citado con su ruta | "sigue las convenciones del proyecto" |
| Cómo se nombran y dónde viven los tests de esa área | el agente infiriéndolo de ejemplos |
| Trampas conocidas de esa zona del código | el agente tropezando con ellas |

Eso va en la sección **Contexto** del archivo de tarea. Una tarea bien escrita se ejecuta
sin abrir nada que no esté declarado.

Regla que lo mantiene honesto: **si un implementador necesita explorar para entender qué
hacer, la tarea estaba incompleta.** No es culpa del agente; es un defecto de planeación,
igual que una colisión de archivos.

### Step 1c — Settle whether the code gets documented

Detect before asking. Open a handful of existing source files and look at what the project
already does: docstrings on public functions, JSDoc, nothing at all.

- **The project has a clear convention** → follow it. Record it and don't ask; asking
  about something the codebase already answers is noise.
- **No convention, or mixed** → ask once:

```
El código existente no tiene una convención clara de documentación.
¿Documentamos lo que se implemente?

  si   docstrings en lo que escriban las tareas
  no   los tests documentan el comportamiento (por defecto)
```

Es binario a propósito. Un desarrollador documenta lo que escribe o no lo documenta;
partirlo por "superficie pública" es una convención de autor de bibliotecas, y la mayoría
de los planes son código de aplicación donde esa línea no significa nada. Si una función
necesita explicación, la necesita esté exportada o no.

Aplica solo al código que las tareas escriben. Dependencias, código generado y archivos
de terceros no entran: no son tuyos para documentar.

Record it in `plan.md` as `documentar_codigo`, and write the chosen style into each task's
**Contexto** so the implementer doesn't have to infer it.

The default is `no` on purpose, and it's a position rather than an omission: tests
describe behavior and can't drift from it, while comments can and do. Make it explicit so
`/cross-review` knows whether a missing docstring is a blocker or a NIT — today it's
always a NIT, which is only right if `no` is the answer.

### Step 1a — Carry the model choice forward

Read `modelo_implementacion` from the spec's frontmatter, or from an earlier `plan.md` in
`docs/plans/`. Write it into this plan's `plan.md`. Ask only if no plan in the project
records it — procedure in `../spec/references/models.md`.

If the session is running on a cheaper model than the one recorded for planning, say so
once:

> Estás planeando con `sonnet` y el proyecto recomienda `opus` para esta fase. La matriz
> de archivos y el grafo de dependencias son lo que decide si el paralelismo funciona.
> ¿Sigo, o prefieres cambiar con `/model` primero?

Then accept whatever they answer. One mention, not a campaign.

### Step 1b — Emit T-000, the baseline task

**Every plan starts with T-000, and every otherwise-dependency-free task depends on it.**
Parallel work can't begin before the project has a working baseline, and a worktree that
can't run the suite is worse than no worktree — it produces red results that mean nothing.

In a mature repository T-000 is mostly verification and closes quickly. Emit it anyway:
the cost of confirming is minutes, and the cost of discovering a missing `.env.example`
with three worktrees already running is all three.

Detalle de qué verifica, el criterio de clon limpio, por qué `.gitignore` es crítico aquí,
y cómo elegir `cmd_setup`: `references/baseline.md`.

Lo que no puede quedar implícito: lo no versionado (`node_modules`, `.venv`, el `.env`
real) **no puede ser producto de una tarea** — está ignorado, así que no queda nada
commiteado y el siguiente worktree no lo tendría. El trabajo de T-000 es hacer que
`cmd_setup` funcione, no instalar nada.

### Step 2 — Slice vertically

Each task delivers one complete working path, not one architectural layer.

```
✗ T-001 Todo el esquema   T-002 Todos los endpoints   T-003 Toda la UI
✓ T-001 Un usuario puede registrarse   (esquema + endpoint + UI de registro)
✓ T-002 Un usuario puede iniciar sesión
```

Horizontal slices serialize everything and share files by construction.

### Step 2b — Inventory what asserts the current behavior

**Run this before declaring files.** The matrix answers *"do these tasks collide?"* It
does not answer *"did we list everything this change invalidates?"* Those are different
questions, and only the second one catches stale text.

Skip it only for purely additive work — a new file, a new endpoint, nothing that
contradicts something already written.

#### When it applies

Any change that reverses or redefines something already true in the repo:

- A default changes
- A rule is removed, inverted, or given an exception
- A name changes — command, file, field, flag, status value
- An interface changes shape
- Something documented as impossible becomes possible, or the reverse
- A dependency or a step is removed

Removals are the worst offenders. Deleting a component leaves every sentence that
mentioned it behind, and those sentences read as current.

Cómo buscarlo, qué superficies revisar, el formato de la tabla y cómo dimensionar las
tareas de documentación: `references/assertion-inventory.md`.

Lo esencial: busca de **tres formas**, porque cada una atrapa lo que las otras no — el
nombre viejo, el concepto escrito en prosa, y la afirmación inversa. Y **toda superficie
necesita tarea dueña**: una sin dueño es un plan incompleto, no documentación para después.

### Step 3 — Declare the files, then build the matrix

For every task, list the files it will create or modify. Concrete paths, not "los
archivos de auth". Include every surface from Step 2b.

Then build a **file → tasks** matrix. This is the heart of the method:

| Archivo | Tareas que lo tocan |
|---|---|
| `src/auth/session.ts` | T-001 |
| `src/auth/login.ts` | T-002 |
| `src/routes/index.ts` | T-002, T-003, T-004 ← **conflicto** |

Every row with more than one task is a collision. Resolve each one, preferring options in
this order:

**a) Split the file.** Usually the cleanest. Per-feature route modules instead of one
router; per-domain migration files instead of one schema file. The conflict disappears
and the codebase gets better.

**b) Extract an upstream task.** One task makes *all* the edits that file needs, and
every consumer depends on it. This is the contract-task pattern: if three tasks each need
to register a route, T-000 registers all three at once against agreed names, and
T-002/T-003/T-004 depend on it. One serialized task instead of three blocked ones.

**c) Chain them.** T-003 depends on T-002 purely because they share a file. Honest, but
it costs the most parallelism. Use it when the file genuinely can't be split.

The plan is valid only when **no row has two tasks in the same wave**.

### Step 4 — Dependencies are the union of two things

A task depends on another when either is true:

1. **Logical:** it can't start until the other exists — it imports its types, queries its
   table, calls its endpoint.
2. **File-based:** they would touch the same file, per Step 3.

Both are real. Write them the same way, and note in the task which kind it is, because a
file-based dependency can often be removed later by splitting the file.

### Step 5 — Compute the waves by hand

Wave 1 is T-000 alone. Everything else depends on it, directly or transitively, so the
first wave is always serial. That's correct: there is nothing to parallelize before the
baseline runs.

Wave 2 = every task whose only dependency is T-000. And so on.

```
Ola 1: T-000                    → 1 agente   (base, siempre sola)
Ola 2: T-001                    → 1 agente
Ola 3: T-002, T-003             → 2 agentes
Ola 4: T-004                    → 1 agente
```

**Verify the graph by hand before writing it down.** There is no tool to catch these for
you, so do it deliberately:

- [ ] Every id in a `depende_de` corresponds to a task that exists
- [ ] Following dependencies from any task never returns to that task (no cycles)
- [ ] Every task appears in exactly one wave
- [ ] No two tasks in the same wave share a file — re-check against the matrix

A task that never lands in a wave means a cycle. Say so and break it: one of those
dependencies isn't real, or there's a shared contract that belongs in its own upstream
task.

The widest wave is the **useful** number of agents, capped at 4. Say it out loud, and be
honest when the answer is 1: a tightly chained plan run with one agent is correct;
running it with three just means two idle agents.

### Step 6 — Write one file per task

`docs/plans/<slug>/tasks/T-00N.md`, using `references/task-format.md`.

**The task file is the state.** Its `estado` field in frontmatter is the truth. One agent
owns one task file and is its only writer. There is no `state.json`, no `log.md`, no
shared board — those would violate the same rule this plan is built on.

Ask once where tasks live:

> ¿Registro las tareas en Linear o en archivos dentro de `docs/plans/<slug>/`?
> (Archivos es lo simple; Linear lo puedes conectar después con `/tracker` y se migra
> todo sin perder progreso.)

In Linear mode, the `tracker` skill mirrors each task file into an issue.

### Step 7 — One approval gate

Present the wave map, the task list with sizes, the **file matrix**, the risks, and the
recommended agent count. Ask for explicit approval.

Show the matrix even when it has no conflicts. It's the evidence that the plan is safe to
run in parallel, and it's something a human can actually check.

Never overwrite a plan with open tasks from different work. Stop and ask.

### Step 8 — Hand off, and recommend stepping the model down

After approval, say what comes next and suggest lowering the session model. **This is the
natural moment**: the expensive part just ended.

Planning is where the irreversible decisions live — the slicing, the file matrix, the
dependency graph. That's done. What remains in this session is coordination: reading
frontmatter, dispatching tasks by name, parsing six-line reports, merging in order. The
implementation agents run on their own model from `modelo_implementacion`, so the session
model no longer governs the code being written — only the orchestration around it.

The orchestrator runs for the whole plan, so the saving compounds across every task.

```
Plan aprobado: 5 tareas, 4 olas, 2 agentes recomendados.

Te recomiendo cambiar a un modelo más ligero antes de ejecutar. Lo que queda en
esta sesión es coordinación —repartir tareas, parsear reportes, mergear— y la
implementación la hacen agentes aparte con su propio modelo.

  /model sonnet

Cámbialo de vuelta por uno más capaz si: aparece un conflicto semántico tras un
merge limpio, una tarea rebota tres veces en revisión, o vas a replanear.

Cuando quieras: /autopilot
```

El mensaje tiene que **recomendar**, no informar. "Los agentes corren con sonnet" es un
dato sobre los subagentes y no le pide nada al usuario; la recomendación es sobre el
modelo de *esta* sesión, y tiene que decirse como tal.

**Recommend one step lighter, not the cheapest available.** The orchestrator still makes the calls
that decide whether the plan survives: is this merge conflict a planning defect, is this
red suite a semantic conflict, does a task bouncing three times mean it's mis-specified.
Those are judgment, and a floor-level model will wave them through.

Skip the suggestion entirely when `modelo_implementacion` is `inherit` — the user already
said they don't want to manage this, and repeating it is nagging.

Say it **once**. If they stay on the same model, that's an answer.

## Sizing

| Size | Files | Rule |
|---|---|---|
| XS | 1 | one function or config change |
| S | 1–2 | one endpoint or one component |
| M | 3–5 | one full feature slice |
| L | 5–8 | **split it** |
| XL | 8+ | **split it, no exceptions** |

Smaller tasks touch fewer files, so they collide less and parallelize more. The file rule
rewards small tasks automatically.

## Output

```
docs/plans/<slug>/
├── spec.md          # de /spec
├── plan.md          # decisiones, matriz de archivos, olas, comandos del proyecto
└── tasks/
    ├── T-001.md     # estado + bitácora adentro; un solo agente escribe cada uno
    └── T-002.md
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Comparten archivo pero editan partes distintas" | Two agents writing one file is a conflict regardless of which lines. It's a dependency. |
| "La carpeta se llama `breakdown/`, escribo ahí y ya" | Then the project stays split between two layouts and the next skill resolves differently. Migrate once. |
| "El agente que implemente ya buscará lo que necesite" | With N agents, that search happens N times, usually on cheaper models. Explore once, here. |
| "El repo ya existe, T-000 sobra" | Verifying costs minutes. A missing `.env.example` found with three worktrees running costs all three. |
| "Pongo 'instalar dependencias' como tarea" | It's gitignored, so nothing gets committed and the next worktree still lacks it. That's `cmd_setup`. |
| "Cada tarea instala lo que necesite" | Two tasks touching the lockfile conflict every time. Dependencies go in T-000 or in exactly one task. |
| "Hago la matriz mental, no la escribo" | The matrix is where you *find* the collisions. Unwritten, you'll miss one. |
| "La matriz ya cubre qué archivos se tocan" | It checks the files you listed. It can't tell you the list is short. |
| "La documentación la actualizo al final" | "Al final" is review, and review is the expensive place to find stale text. |
| "Busqué el símbolo y no aparece en más lados" | Prose that asserts the old rule has no symbol. Search the concept and the inverse claim too. |
| "Es solo un rename, no cambia comportamiento" | A rename invalidates every sentence that used the old name. Renames are the worst case. |
| "Declaro los archivos por encima, ya se verá" | Vague declarations make the matrix useless and the guarantee fake. |
| "Marco todo como dependiente, por si acaso" | That serializes the plan and wastes the extra agents. Only real dependencies. |
| "Esta tarea es grande pero la entiendo" | The agent picking it up in a fresh context doesn't. Split it. |
| "Reemplazo el plan viejo, ya está obsoleto" | Its open tasks may be mid-build in another terminal. Ask. |
| "Hay varios specs, tomo el más reciente" | The user may have written three and want the oldest. Show them and let them pick. |
| "Planeo cada spec por separado, es más limpio" | Then nothing checks for file collisions between plans, and those are the worst ones to debug. |

## Red Flags

- Writing into a `breakdown/` directory instead of migrating it to `tasks/`
- Migrating while a wave is in flight — agents hold resolved paths and live worktrees
- Merging `tasks/` and `breakdown/` automatically when both exist
- A plan with no T-000
- A task whose Contexto says "sigue las convenciones" instead of citing a file
- A task that forces the implementer to search for a signature the planner already read
- A task whose output is `node_modules` or `.venv` — those are `cmd_setup`, not deliverables
- Two tasks that both modify a dependency manifest or lockfile
- T-000 marked done without running the fresh-clone check
- A behavior reversal planned with no assertion inventory
- An inventory built only from a symbol search, so prose assertions went unseen
- A surface listed in the inventory with no task that owns it
- Documentation deferred to "al final" instead of being a task with criteria
- A file appearing in two tasks of the same wave
- An "archivos" section that says things like "los de auth"
- Any task without testable acceptance criteria
- Horizontal slices (all schema / all API / all UI)
- No dependencies anywhere in a multi-task plan — usually means the matrix wasn't built
- A `depende_de` pointing at a task that doesn't exist
- A task that never lands in any wave (that's a cycle)
- A shared `state.json`, `log.md` or board file that several agents write
- Picking a spec silently when several exist
- Planning a spec still in `borrador`
- Replacing a plan that has open tasks without asking
- A per-plan matrix when several plans were selected — cross-plan collisions go unseen
- Repeating the model suggestion after the user already chose to stay
- Suggesting the cheapest model for the orchestrator, which still has to judge stop conditions
- Writing to the repo root instead of `docs/plans/<slug>/`
- Starting to implement in the same turn the plan was approved

## Verification

- [ ] Every spec found was shown to the user, with its state and validation, before planning
- [ ] Nothing in `borrador` was planned
- [ ] Any existing plan with open tasks was confirmed before being touched
- [ ] With several specs selected: the file matrix spans all of them, and cross-plan
      dependencies are written qualified (`<plan>/T-00N`)
- [ ] T-000 exists and every otherwise-dependency-free task depends on it
- [ ] T-000's criteria include the fresh-clone check with the project's real commands
- [ ] `cmd_setup` matches the project's existing lockfile, and uses the frozen form
- [ ] If no package manager is available for a stack in use, the user was told to install
      one instead of being worked around
- [ ] `.gitignore` covers dependencies, build artifacts and secrets
- [ ] `.env.example` lists every variable the suite reads
- [ ] No task other than T-000 adds dependencies, unless exactly one task owns the
      manifest and the lockfile together
- [ ] A legacy plan layout was migrated to `tasks/` + `plan.md` before planning, in its
      own commit, with internal references corrected
- [ ] An approved spec existed before planning started
- [ ] For any change that reverses existing behavior, the assertion inventory was built
      and written into `plan.md`
- [ ] Every surface in the inventory has an owning task
- [ ] The inventory was built by searching for the old name, the old concept in prose,
      and the inverse claim — not only by symbol
- [ ] Templates, examples, help text and the plan's own artifacts were checked
- [ ] Every task's Contexto section carries concrete paths, real signatures and the
      pattern to follow, so the implementer doesn't have to explore
- [ ] Every task declares its files as concrete paths
- [ ] The file → tasks matrix is written into `plan.md`
- [ ] **No file appears in two tasks of the same wave**
- [ ] Every collision was resolved by splitting, extracting upstream, or chaining
- [ ] Every `depende_de` points at a task that exists
- [ ] No cycles: every task lands in exactly one wave
- [ ] Every task is S or M, with acceptance criteria and a verification command
- [ ] `plan.md` frontmatter records the project's real test, build and lint commands
- [ ] `documentar_codigo` is set — detected from the codebase, or asked once when unclear
- [ ] Each task's Contexto states the documentation style, so the implementer doesn't infer it
- [ ] Nothing shared is written by more than one agent
- [ ] The wave map, the matrix and the recommended agent count were shown to the user
- [ ] The user explicitly approved before anything was implemented
- [ ] After approval, the model step-down was suggested once, with what to raise it back
      for — and skipped if `modelo_implementacion` is `inherit`
