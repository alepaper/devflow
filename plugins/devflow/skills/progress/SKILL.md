---
name: progress
argument-hint: "[nombre-del-plan]"
description: Reports where a plan stands by reading its task files — what's done, what's in flight and by whom, what's blocked and why, what's ready to pick up now, and the next decision the user owes. Read-only, changes nothing. Use whenever the user asks "¿cómo va?", "¿en qué vamos?", "estado", "qué falta", "qué está bloqueado", "¿puedo seguir?", or asks for a progress report on a plan or feature under development.
---

# Progress — Where the Plan Stands

## Overview

Read the task files and say where things are. **Change nothing** — not a status field, not a
task file, not a commit. If something looks wrong, report it; don't fix it here.

There is no central board to query. Each task file's `estado` frontmatter is the truth, and
you assemble the picture by reading them.

**Language:** report in Spanish.

## When to Use

- The user asks how the work is going, what's left, or whether they can continue
- Before running `/autopilot`, to see what's ready
- After a break, to rebuild context on a plan
- `/autopilot status` delegates here

**When NOT to use:** the user wants work done — that's `/autopilot`. Never start
implementing from a progress check.

## The Process

### 1. Find the plan

`$ARGUMENTS` may name it. Otherwise look under `docs/plans/`:

- One plan → use it
- Several, one with open tasks → use that one
- Several with open tasks → list them and ask which

### 2. Read every task file

Resolve the directory first: `tasks/`, falling back to `breakdown/`. The plan document is
`plan.md`, falling back to `tasks.md` then `breakdown.md`. Older projects carry those
legacy names from two over-broad renames.

**Report the legacy layout; don't migrate it.** This skill is read-only, and the rename
belongs to a skill that's about to work on the plan anyway:

> El plan usa el layout viejo (`breakdown/`). `/breakdown` o `/autopilot` lo migran solo
> la próxima vez que corran.


`docs/plans/<slug>/tasks/*.md`. From each frontmatter: `estado`, `depende_de`, and the
agent and review rounds from its bitácora.

### 3. Classify

| Bucket | Rule |
|---|---|
| **Hechas** | `estado: done` |
| **En vuelo** | `in_progress` or `in_review` — name the agent |
| **Listas ahora** | `pending` **and** every `depende_de` is `done` |
| **Esperando** | `pending` with a dependency not done — name the blocking task |
| **Devueltas** | `changes_requested` — say how many rounds |
| **Bloqueadas** | `blocked` — say why |

"Listas ahora" is the one the user actually acts on. Lead with it when anything is ready.

### 4. Report in prose, short

Counts first, then what matters. A table of every task is rarely what someone wants when
they ask "¿cómo va?" — give the shape, and the detail only where there's a problem.

Always end with **the next decision the user owes you**, if there is one. If there isn't,
say the plan can continue unattended.

### 5. Check for orphan worktrees

```bash
git worktree list
```

Anything beyond the main repository that doesn't match a task currently `in_progress` or
`in_review` is an orphan from a session that ended early. Each holds a full copy of the
project's dependencies, so report them with their size:

```bash
du -sh ../<repo>-*
```

Report, don't remove — this skill is read-only. Say which ones and how much they hold, so
the user or `/autopilot` can clear them.

### 6. Flag what looks wrong

Say it, don't fix it:

- A task `in_progress` across several sessions with no new bitácora entries
- A task `done` whose bitácora shows no review verdict
- A `depende_de` pointing at a task that doesn't exist
- Task files and Linear disagreeing — report both, don't silently pick one
- Two in-flight tasks whose declared files overlap — that's a plan defect that will
  cause a collision
- Orphan worktrees, with how much disk they're holding
- A legacy directory layout, named but not changed
- Both `tasks/` and `breakdown/` present — a half-finished migration, which needs a human

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Ya que estoy, arreglo ese estado" | This is read-only. A silent write hides whatever caused the drift. |
| "Listo todas las tareas en una tabla" | Nobody asked for an inventory. Give the shape and the problems. |
| "Esta tarea lleva días pero seguro va bien" | An `in_progress` with no bitácora entries is a stall. Say so. |
| "El tablero dice otra cosa, uso el archivo y ya" | Report the disagreement. A human may have moved that card deliberately. |
| "Está todo listo, arranco el autopilot" | Reporting isn't permission. The user asks for work separately. |

## Red Flags

- Writing to any file during a progress check
- Starting implementation after reporting
- Reporting "todo bien" without having read the task files
- Numbers that don't match the files
- Omitting the next decision when one is pending

## Verification

- [ ] Every task file was read; nothing was inferred from memory
- [ ] Nothing was written or committed
- [ ] "Listas ahora" only lists tasks whose dependencies are all `done`
- [ ] Blocked tasks name what blocks them
- [ ] Orphan worktrees were reported with their size, not removed
- [ ] A legacy layout was reported, not migrated
- [ ] Anomalies were flagged, not repaired
- [ ] The report ends with the next decision the user owes, or says none is pending
