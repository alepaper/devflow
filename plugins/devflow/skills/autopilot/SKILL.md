---
name: autopilot
argument-hint: "[dev | test | review | task T-00N | all]"
description: Executes an approved plan by dispatching tasks to one or several agents — the orchestrator assigns, nobody self-claims. Each task is implemented test-first, reviewed by a DIFFERENT agent (Claude subagent or an external CLI like codex), committed individually, and logged in its own task file. Also reports progress and notifies when each task and the whole plan finish. Use whenever the user says "autopilot", "arranca el desarrollo", "ejecuta el plan", "sigue con las tareas", "¿cómo va?", "estado", or asks to run only part of the loop (solo desarrollar, solo probar, solo revisar). Requires an approved plan from /breakdown.
---

# Autopilot — Dispatched Parallel Execution

## Overview

Autopilot removes the human from *between* tasks, not from the verification. Every task
earns failing tests first, a passing suite, a clean build, a review by a **different
agent**, and its own commit.

Three invariants, none negotiable:

1. **No code counts as done without tests written before it.**
2. **No agent reviews its own code.** Ever. Not with a fresh prompt, not "carefully".
3. **No agent picks its own task.** You — the orchestrator — assign them.

Autonomy relaxes none of these. Running unattended is exactly when they matter most:
nobody notices the shortcut until morning.
4. **Con más de un agente, cada tarea corre en su propio worktree.** Sin aislamiento, la
   compuerta de suite verde del paso 6 no se puede hacer cumplir: un rojo por trabajo
   ajeno a medias es indistinguible de una regresión propia.

That third one is what replaces the old locking engine. Self-service claiming has a
race: two agents read the board in the same instant, both see T-002 pending with its
dependencies met, both take it. With a single dispatcher there is nothing to race on.

**Language:** talk to the user in Spanish.

**No scripts.** State lives in the task files. You read them, you decide, you assign.

## When to Use

- An approved plan exists at `docs/plans/<slug>/plan.md` with task files
- The user wants to run all of it, or just one stage of it
- The user asks how the work is going

**Hard precondition:** no approved plan → stop and run `/breakdown`. Never invent tasks.

## Modes

`$ARGUMENTS` picks the mode. The loop is **usable in pieces** — develop today, review
tomorrow.

| Invocation | What it runs |
|---|---|
| `/autopilot` or `all` | Full loop until the plan is done or something blocks |
| `dev` | Implement test-first, leave tasks in `in_review`, stop. No review pass. |
| `test` | Run the whole suite, fix red tests, fill coverage gaps. No new features. |
| `review` | Review everything sitting in `in_review`. No implementation. |
| `task T-003` | Just that task, full loop |
| `status` | Board only, changes nothing |

Anything unrecognized → treat as `all` and say which mode you picked.

## Setup, once per run

### 1. Read the board
**Legacy layouts.** Before anything else, resolve the plan directory. Some projects were
created with `breakdown/` instead of `tasks/`, or `tasks.md` / `breakdown.md` instead of
`plan.md` — two over-broad command renames dragged artifact paths along with them.

Read `tasks/` first, falling back to `breakdown/`; `plan.md` first, falling back to
`tasks.md` then `breakdown.md`. If a legacy name is found, **migrate it with `git mv`
before working**, in its own commit, and tell the user in one line. If both the canonical
and the legacy name exist, stop and ask — merging them blindly can lose task files.

Procedure: `../breakdown/references/plan-layout.md`.


Read **only the frontmatter** of each file in `docs/plans/<slug>/tasks/` — you need
`estado` and `depende_de`, nothing else. Reading 20 full task files every round, when the
first ten lines of each answer the question, is context you pay for on every iteration.

Read a task's body when you're about to dispatch it, not before.

Their `estado` frontmatter is the truth.
Build the picture yourself:

- **done** — finished and approved
- **pending** with every `depende_de` in state `done` → **ready now**
- **pending** with any dependency not done → blocked by the plan, not by a problem
- **in_progress**, **in_review**, **changes_requested**, **blocked** — in flight

### 2. Check the tree

```bash
git status --porcelain
```

Dirty tree with changes unrelated to the plan → **stop and ask**. Per-task commits must
not absorb unrelated local work, or the rollback guarantee breaks.

### 3. Ask how many agents

Show the ready set and the wave map from `plan.md`, then ask:

> La ola actual tiene 3 tareas listas: T-002, T-003, T-005.
> ¿Con cuántos agentes arranco? (recomendado: 3)

Cap at 4. Say plainly when the honest answer is 1 — a plan where each task unlocks the
next runs with one agent, and that's correct, not a failure.

### 3a. T-000 first, always

The baseline task gates everything. Until T-000 is `done`, there are no worktrees and no
parallel agents — a worktree that can't run the suite produces red results that mean
nothing, and you'd debug the same missing `.env.example` in every one of them.

Run it alone, on the integration branch:

```
/autopilot task T-000
```

It closes when a fresh clone passes `cmd_setup`, `cmd_test` and `cmd_build`. That check
is what proves every later worktree will work.

If the repository has no commits yet, T-000 makes the first one. `git worktree add` fails
without it.

### 3b. Clear orphan worktrees before creating new ones

A session that ended mid-plan leaves worktrees behind, each holding a full copy of the
project's dependencies.

```bash
git worktree list          # todo lo que no sea el repo principal ni una tarea en vuelo
```

Remove them before starting. Creating a new wave on top of orphans is how a machine ends
up with eight copies of `node_modules`. See `references/worktrees.md`.

### 3c. Create one worktree per task — only when running more than one agent

**One agent: no worktrees.** Work directly on the integration branch. There's nothing to
isolate from, and `cmd_setup` would be paid for nothing.

**Two or more agents: one worktree per task, no exceptions.** Not because of file
collisions — the matrix already prevents those. Because of TDD.

Each of the three steps of the loop asks a question that a shared tree makes
unanswerable:

| Paso | La pregunta | Qué pasa en árbol compartido |
|---|---|---|
| RED | ¿falló por la razón correcta? | Puede haber fallado por el módulo a medio escribir de otro agente |
| GREEN | ¿pasó por mi código? | Puede haber pasado por el de otro |
| Suite completa | ¿rompí algo? | Rojo por trabajo ajeno, indistinguible del propio |

El tercero es el que decide. Al terminar, el agente corre la suite completa antes de
commitear. Si está roja por el estado intermedio de otro, tiene dos salidas: esperar — y
entonces ya serializó, el paralelismo se perdió igual — o decidir que "esos fallos no son
míos" y commitear. Lo segundo convierte la compuerta en teatro, y no hay forma confiable
de separar la regresión propia del trabajo ajeno a medias.

Sin aislamiento, **la compuerta de suite verde no se puede hacer cumplir**. Esa es la
razón, no el ruido.

Montaje, preparación con `cmd_setup`, orden de merge, qué hacer ante un conflicto y
limpieza: `references/worktrees.md`.

Un worktree nuevo no trae `node_modules` ni `.env`. Si `cmd_setup` falta y el proyecto lo
necesita, **para y pregunta antes de crear ninguno**: descubrirlo con tres ya creados
desperdicia los tres.

### 4. Confirm the reviewer

Read `reviewer` from `plan.md` frontmatter. If it's an external CLI, **verify it responds
before the first task** — finding out it's missing after five tasks is a bad time. See
the `cross-review` skill.

## The dispatch loop

This is the orchestrator's loop. Repeat until the plan is done or something blocks.

### 1. Recompute the ready set

Re-read the task files. A task is ready when `estado: pending` and every id in
`depende_de` has `estado: done`.

Do this **after every completion, not once per wave**. Waves describe the graph's shape;
they are not a schedule. If T-002 finishes and T-004 only depended on T-002, dispatch
T-004 immediately — making it wait for T-003 to finish the "wave" wastes exactly the hours
this is built to use.

An agent that frees up gets the next ready task right away. The pipeline stays full.

### 2. Assign, don't offer

Pick up to N ready tasks and hand each to one agent, **naming the task explicitly**. The
agent never chooses. If fewer tasks are ready than agents available, run fewer agents —
that's the plan being serial, and inventing work for the idle ones is how collisions
happen.

Before dispatching a batch, re-check against the file matrix in `plan.md`: the tasks you
are about to run in parallel must not share a file. The planner guaranteed this, but
plans get edited.

### 3. Each agent runs its task

Dispatch to the **`devflow-implementer`** subagent that ships with this plugin. It
declares `skills: [tdd]`, so the TDD skill enters its context deterministically — not
because the agent chose to load it. For a mandatory invariant, "the agent will probably
load it" is too thin a thread.

The injection is **scoped on purpose**: the implementer gets `tdd` because it writes
code; `devflow-reviewer` doesn't, because judging someone else's tests needs the review
prompt, not the authoring loop; and you, the orchestrator, never load it at all. A skill
injected where it isn't used is context paid for on every turn for nothing.

Override the subagent's `model` per call from `modelo_implementacion` in `plan.md` when
it's set, and its `maxTurns` from the task's dependent count — see the budget table below.

If the subagent isn't available — devflow installed as plain skills rather than as a
plugin — fall back to a generic agent and tell it **by name** to load the `tdd` skill.

Each agent returns a **fixed six-line block** — task, status, tests, commit, files,
blocker — and nothing else. Its final message lands in your context for the rest of the
plan, so prose there multiplies by every task. The detail lives in the task's bitácora.

See `references/agent-brief.md` for the exact brief to give each one. The shape:

claim nothing → read the task file → **RED**: write failing tests, record the failure line
in the bitácora → **GREEN**: minimum code → **REFACTOR** → full suite + build + lint →
commit only the declared files → set `estado: in_review` in its own task file → **stop,
without approving itself**.

### 4. Review each finished task

Invoke the `cross-review` skill per task. The reviewer must differ from the implementer.

- **APPROVED** → `estado: done`, notify, the task's dependents may now be ready
- **CHANGES_REQUESTED** → `estado: changes_requested` with the blockers in the bitácora.
  Back to the implementing agent. After **3 rounds**, stop and escalate — the task is
  mis-specified, not badly implemented.
- **BLOCKED** → `estado: blocked`, notify, stop. **Remove its worktree** and keep the
  branch: a blocked task can sit for days holding the same disk as an active one, and the
  branch preserves whatever work exists until the user decides.

### 5. Merge into the integration branch

An approved task merges immediately, not at the end. Merging six branches at once is a
worse problem than merging one six times.

Orden de dependencia, nunca de terminación, con `--no-ff` y la suite verde después de
cada merge. El worktree se elimina aquí mismo. Procedimiento completo en
`references/worktrees.md`.

Dos fallos distintos que no hay que confundir:

**Conflicto de merge** = el plan estaba mal, dos tareas compartían un archivo. No lo
resuelvas a mano: regístralo, para, arregla el plan. Una resolución improvisada repara el
síntoma y deja el defecto para la siguiente ola.

**Merge limpio con suite roja** = conflicto semántico. Las tareas no tocaron ningún
archivo común pero cambiaron el mismo comportamiento. La exclusividad de archivos nunca
prometió prevenir esto. Es condición de parada: nombra las dos tareas y deja que el
usuario decida.

Al terminar el plan, la rama de integración va una sola vez a la rama base, y la limpieza
se verifica en vez de asumirse:

```bash
git worktree list                        # solo el repositorio principal
git branch --list 'devflow/<plan>-*'     # vacío
```

### 6. Notify

Per task and at the end. See `references/notifications.md` — one shell line, no tooling.

### 7. Loop

Back to step 1.

## State: where it lives, who writes it

Each task file is written by **exactly one agent** — the one working that task. That's
the same file-exclusivity rule the plan is built on, applied to the plan's own artifacts.

A shared `state.json`, a shared `log.md`, or a board file several agents update would all
break it. Don't create them. Per-task history goes in that task's own bitácora section.

`plan.md` is written only by the orchestrator, never by a working agent.

## Autonomous by default — resolve, don't park

`/autopilot` runs unattended for hours. **It resolves. It doesn't ask, and it almost never
abandons a task.**

### The distinction that makes it work

> **Acceptance criteria are the contract. The approach is not.**

The criteria come from the spec the user approved. The approach — which library, which
structure, which exact signature — was proposed by the planner before any code existed.

An agent that can't make the planned approach work **changes the approach**. It does not
park. As long as the criteria are met, the task is done correctly even if it looks nothing
like the Contexto said.

Almost everything that used to block lands here: the library doesn't do what was assumed,
the signature doesn't fit, the neighbouring pattern doesn't apply. None of that is a
blocker — it's what you only learn by building.

### The ladder

1. **Retry.** Execution error: a bad import, a mock wired wrong.
2. **Change the approach.** Pick another that meets the same criteria, update the task's
   Contexto with what you actually did, record the decision. Criteria untouched.
3. **Adjust downstream.** The new approach changes what dependent tasks will consume.
   Update their Contexto before anyone picks them up. Their criteria are untouched too.
4. **Stop the run.** Only when an **acceptance criterion** can't be met. That isn't an
   implementation problem: the spec asks for something that can't be built as written,
   and no change of approach fixes it.

Steps 1–3 are normal work, not exceptions. Step 4 should be rare; if it happens often the
problem is in `/spec`, not here.

### When the run actually ends

There is no general "park and continue". In a dependency graph, abandoning an upstream
task kills everything hanging off it — continuing with "the rest" when there is no rest
just burns the night.

So: a task that can't be resolved and **has dependents** ends that branch. If ready tasks
remain elsewhere, continue with them; if none remain, **the run ends and says why**. A
task with no dependents is a leaf — mark it and keep going, nothing needed it.

Ending early with an honest report beats pretending to work with nothing executable.

### Retry budget follows the graph

Giving up on a task costs whatever its descendants cost. Before abandoning one, count how
many tasks depend on it, directly or transitively:

Count how many tasks depend on it, directly or transitively, and **pass `maxTurns`
accordingly when dispatching** — the subagent's default of 30 is the leaf case:

| Dependientes | `maxTurns` | Presupuesto |
|---|---|---|
| 0 (hoja) | 30 | Normal. Abandonarla cuesta una tarea. |
| 1–2 | 45 | Prueba al menos dos enfoques distintos antes de rendirte. |
| 3 o más, o es T-000 | 60 | Agota el peldaño 3. Rendirse aquí termina la corrida. |

Without the override the policy is decorative: every task would get the same 30 turns
regardless of whether abandoning it costs one task or the whole plan.

### Pre-authorize the irreversible, once, at the start

The one exception to "decide it yourself". `git revert` undoes code; it does not undo a
dropped column, a payment, deleted records, or a leaked secret. At 3am with nobody
watching there is no recovery.

Ask once at launch, **showing how many tasks depend on each** — excluding a leaf costs one
task, excluding an upstream one costs its whole subtree:

```
2 tareas tocan cosas que `git revert` no deshace:

  T-004  migración que elimina la columna `usuarios.legacy_id`   (2 tareas dependen)
  T-007  borrado de registros huérfanos en producción            (hoja)

  autorizar   las ejecuto sin preguntar
  excluir     las saco de esta corrida y de lo que dependa de ellas
```

No such tasks → don't ask at all. Once answered, nothing else is asked for the rest of the
run.

### Record what you decided

Append to `docs/plans/<slug>/decisiones.md` — written only by you, so nothing contends on
it. Five fields: what was expected, what you did, whether the criteria still hold, whether
it propagated downstream, and whether it's reversible.

**"Propagated downstream" is the one that matters in the morning**: it says whether the
change stayed inside one task or rippled through the plan.

Obvious calls get no entry. The file is only useful if it reads in two minutes.

Full policy: `references/autonomy.md`.

## Status reporting

`/autopilot status` delegates to the `progress` skill, which reads the task files and
reports without changing anything. Use `/progress` directly when that's all you want.

## Finishing

When no open tasks remain: notify `all-done`, then summarize tasks completed, tests
added, commits made, review rounds that needed a second pass, and anything left for the
user. If worktrees were used, list branches still pending merge.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Que cada agente tome la tarea que quiera, es más simple" | Two agents can read the board in the same instant and take the same task. You assign. |
| "Tengo 3 agentes y 1 tarea lista, le doy algo al resto" | Inventing work outside the ready set is exactly how collisions happen. Run one. |
| "Dejo que el agente resuma lo que hizo, es más informativo" | Its message stays in your context all plan. Fifteen prose reports is ~30k tokens that also degrade your decisions. |
| "El agente ya sabe hacer TDD, no hace falta nombrar la skill" | It'll follow the four-line summary and skip the checks. Name it. |
| "Esta tarea es trivial, el test sobra" | Trivial code breaks too, and now nothing tells you when. |
| "Me reviso yo mismo, con cuidado" | You share the blind spot that produced the code. |
| "El suite tarda, corro solo los tests de mi tarea" | That's how a regression ships. |
| "Junto tres tareas en un commit" | You lost the clean rollback point that was the reason for per-task commits. |
| "Dos agentes necesitan el mismo archivo, que se coordinen" | The plan is wrong. Fix the plan, don't coordinate around it. |
| "El repo ya está armado, me salto T-000" | Then the first thing you learn in three worktrees at once is what's missing. Verify once. |
| "Los worktrees los limpio al final, total" | Each one holds a full copy of the dependencies. Four tasks is four `node_modules`. |
| "La tarea quedó bloqueada, dejo el worktree por si acaso" | It can sit for days holding the same disk as an active one. Remove it; the branch keeps the work. |
| "`remove` se queja, le pongo `--force`" | Those untracked files may be work the task never declared. Look before destroying. |
| "Le instalo las dependencias a mano al worktree" | You just hid a T-000 defect. The next worktree has the same problem. |
| "Está bloqueado pero creo que sé qué quiso decir" | Guessing at a blocker builds the wrong thing confidently. Ask. |

## Red Flags

- An agent choosing its own task
- Running more agents than there are ready tasks
- Two agents in flight whose tasks share a file
- Two or more agents running in the same working tree
- A merge conflict resolved by hand instead of escalated as a planning defect
- Branches merged in completion order instead of dependency order
- A merge that didn't run the full suite afterwards
- Worktrees left behind after their branches merged, or after a task was blocked
- `git worktree remove --force` used without first listing what it would destroy
- A new wave created while orphan worktrees from a previous session still exist
- A task marked `done` whose tests were written after the implementation
- The same agent implementing and reviewing
- `git add -A` anywhere
- A commit spanning more than one task
- Skipping the full suite because the focused tests passed
- Continuing past CHANGES_REQUESTED
- Creating a shared state or log file that several agents write
- Touching auth, payments or migrations without explicit sign-off

## Verification

- [ ] Every task was assigned by the orchestrator, never self-selected
- [ ] No two tasks running in parallel shared a file
- [ ] A legacy plan layout was migrated before dispatching, never mid-wave
- [ ] T-000 closed, with the fresh-clone check passing, before any worktree was created
- [ ] Every parallel task ran in its own worktree, prepared with `cmd_setup`
- [ ] Branches merged in dependency order, with the full suite green after each merge
- [ ] Any conflict was escalated as a planning defect, not resolved ad hoc
- [ ] Every worktree was removed when its task merged, was blocked, or was abandoned
- [ ] Nothing was force-removed without first inspecting the untracked files
- [ ] At the end, `git worktree list` shows only the main repository and no
      `devflow/<plan>-*` task branches remain
- [ ] Implementation ran through `devflow-implementer`, or `tdd` was named explicitly in
      the fallback
- [ ] `tdd` was not injected into the reviewer or the orchestrator
- [ ] Agents returned the fixed report block, not prose
- [ ] Every completed task's bitácora records the RED output and the test/build/lint results
- [ ] The ready set was recomputed from frontmatter, not from full task files
- [ ] Every completed task has tests that were written before its implementation
- [ ] Every completed task was reviewed by a different agent
- [ ] Every completed task has exactly one commit, containing only its declared files
- [ ] Each task file was written only by its own agent
- [ ] No shared state, log or board file was created
- [ ] The full suite and the build are green at the end
- [ ] Notifications fired per task and at plan completion
- [ ] Nothing on the "puntos de parada obligatoria" list shipped without sign-off
- [ ] The run never halted waiting for an answer after launch
- [ ] Irreversible tasks were authorized or excluded at the start, with their dependent
      count shown — never improvised mid-run
- [ ] No task was abandoned before trying a different approach, with `maxTurns` passed
      per task according to its dependent count
- [ ] Tasks were dispatched as soon as their dependencies cleared, not at wave boundaries
- [ ] No acceptance criterion was altered to make a task pass
- [ ] Every non-obvious autonomous decision is in `decisiones.md` with its four fields
- [ ] An early end named the unmet criterion and the tasks blocked by dependency
- [ ] The integration branch is green: any merge that broke it was reverted and the task retried with a different approach
