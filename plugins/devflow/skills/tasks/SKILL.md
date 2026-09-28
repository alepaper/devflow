---
name: tasks
argument-hint: "[nombre-del-plan]"
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

`$ARGUMENTS` may name the plan. If it's empty, use the most recently approved spec.

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

### Step 1 — Read-only reconnaissance

Read the spec and the code it touches. Note existing patterns, the test setup, and **the
real commands**: how tests run, how the build runs, how lint runs. Record them in
`plan.md` frontmatter — the autopilot will need them and there is no config file anymore.

Write no code during planning.

### Step 2 — Slice vertically

Each task delivers one complete working path, not one architectural layer.

```
✗ T-001 Todo el esquema   T-002 Todos los endpoints   T-003 Toda la UI
✓ T-001 Un usuario puede registrarse   (esquema + endpoint + UI de registro)
✓ T-002 Un usuario puede iniciar sesión
```

Horizontal slices serialize everything and share files by construction.

### Step 3 — Declare the files, then build the matrix

For every task, list the files it will create or modify. Concrete paths, not "los
archivos de auth".

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

Wave 1 = every task with no dependencies. Wave 2 = every task whose dependencies are all
in wave 1. And so on.

```
Ola 1: T-001                    → 1 agente
Ola 2: T-002, T-003             → 2 agentes
Ola 3: T-004                    → 1 agente
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
| "Hago la matriz mental, no la escribo" | The matrix is where you *find* the collisions. Unwritten, you'll miss one. |
| "Declaro los archivos por encima, ya se verá" | Vague declarations make the matrix useless and the guarantee fake. |
| "Marco todo como dependiente, por si acaso" | That serializes the plan and wastes the extra agents. Only real dependencies. |
| "Esta tarea es grande pero la entiendo" | The agent picking it up in a fresh context doesn't. Split it. |
| "Reemplazo el plan viejo, ya está obsoleto" | Its open tasks may be mid-build in another terminal. Ask. |

## Red Flags

- A file appearing in two tasks of the same wave
- An "archivos" section that says things like "los de auth"
- Any task without testable acceptance criteria
- Horizontal slices (all schema / all API / all UI)
- No dependencies anywhere in a multi-task plan — usually means the matrix wasn't built
- A `depende_de` pointing at a task that doesn't exist
- A task that never lands in any wave (that's a cycle)
- A shared `state.json`, `log.md` or board file that several agents write
- Writing to the repo root instead of `docs/plans/<slug>/`
- Starting to implement in the same turn the plan was approved

## Verification

- [ ] An approved spec existed before planning started
- [ ] Every task declares its files as concrete paths
- [ ] The file → tasks matrix is written into `plan.md`
- [ ] **No file appears in two tasks of the same wave**
- [ ] Every collision was resolved by splitting, extracting upstream, or chaining
- [ ] Every `depende_de` points at a task that exists
- [ ] No cycles: every task lands in exactly one wave
- [ ] Every task is S or M, with acceptance criteria and a verification command
- [ ] `plan.md` frontmatter records the project's real test, build and lint commands
- [ ] Nothing shared is written by more than one agent
- [ ] The wave map, the matrix and the recommended agent count were shown to the user
- [ ] The user explicitly approved before anything was implemented
