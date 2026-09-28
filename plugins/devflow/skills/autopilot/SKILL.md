---
name: autopilot
argument-hint: "[dev | test | review | task T-00N | all]"
description: Executes an approved plan by dispatching tasks to one or several agents — the orchestrator assigns, nobody self-claims. Each task is implemented test-first, reviewed by a DIFFERENT agent (Claude subagent or an external CLI like codex), committed individually, and logged in its own task file. Also reports progress and notifies when each task and the whole plan finish. Use whenever the user says "autopilot", "arranca el desarrollo", "ejecuta el plan", "sigue con las tareas", "¿cómo va?", "estado", or asks to run only part of the loop (solo desarrollar, solo probar, solo revisar). Requires an approved plan from /tasks.
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

That third one is what replaces the old locking engine. Self-service claiming has a
race: two agents read the board in the same instant, both see T-002 pending with its
dependencies met, both take it. With a single dispatcher there is nothing to race on.

**Language:** talk to the user in Spanish.

**No scripts.** State lives in the task files. You read them, you decide, you assign.

## When to Use

- An approved plan exists at `docs/plans/<slug>/tasks.md` with task files
- The user wants to run all of it, or just one stage of it
- The user asks how the work is going

**Hard precondition:** no approved plan → stop and run `/tasks`. Never invent tasks.

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

Read every file in `docs/plans/<slug>/tasks/`. Their `estado` frontmatter is the truth.
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

### 4. Confirm the reviewer

Read `reviewer` from `plan.md` frontmatter. If it's an external CLI, **verify it responds
before the first task** — finding out it's missing after five tasks is a bad time. See
the `cross-review` skill.

## The dispatch loop

This is the orchestrator's loop. Repeat until the plan is done or something blocks.

### 1. Recompute the ready set

Re-read the task files. A task is ready when `estado: pending` and every id in
`depende_de` has `estado: done`.

Do this **fresh each round**. A task that finished since the last round may have unlocked
others.

### 2. Assign, don't offer

Pick up to N ready tasks and hand each to one agent, **naming the task explicitly**. The
agent never chooses. If fewer tasks are ready than agents available, run fewer agents —
that's the plan being serial, and inventing work for the idle ones is how collisions
happen.

Before dispatching a batch, re-check against the file matrix in `plan.md`: the tasks you
are about to run in parallel must not share a file. The planner guaranteed this, but
plans get edited.

### 3. Each agent runs its task

See `references/agent-brief.md` for the exact brief to give each one. The shape:

claim nothing → read the task file → **RED**: write failing tests → **GREEN**: minimum
code → **REFACTOR** → full suite + build → commit only the declared files → set
`estado: in_review` in its own task file → **stop, without approving itself**.

### 4. Review each finished task

Invoke the `cross-review` skill per task. The reviewer must differ from the implementer.

- **APPROVED** → `estado: done`, notify, the task's dependents may now be ready
- **CHANGES_REQUESTED** → `estado: changes_requested` with the blockers in the bitácora.
  Back to the implementing agent. After **3 rounds**, stop and escalate — the task is
  mis-specified, not badly implemented.
- **BLOCKED** → `estado: blocked`, notify, stop.

### 5. Notify

Per task and at the end. See `references/notifications.md` — one shell line, no tooling.

### 6. Loop

Back to step 1.

## State: where it lives, who writes it

Each task file is written by **exactly one agent** — the one working that task. That's
the same file-exclusivity rule the plan is built on, applied to the plan's own artifacts.

A shared `state.json`, a shared `log.md`, or a board file several agents update would all
break it. Don't create them. Per-task history goes in that task's own bitácora section.

`plan.md` is written only by the orchestrator, never by a working agent.

## Stop conditions — do not push through

Stop, notify, and ask the user when:

- A test can't be made to pass, or the build breaks without an obvious fix
- The spec is ambiguous, or the task needs a decision the spec doesn't cover
- Review came back CHANGES_REQUESTED three times on one task
- The task touches anything on the plan's **puntos de parada obligatoria**: auth or
  permissions, destructive migrations, payments, deletions, secrets, **or anything you
  cannot undo with `git revert`**
- An agent reports it needs a file its task didn't declare
- Two agents produced conflicting changes — which now means the plan had a collision the
  matrix missed, so fix the plan before continuing

Re-invoking `/autopilot` resumes from the ready set. State is in the task files, so
resuming across sessions is free.

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
| "Esta tarea es trivial, el test sobra" | Trivial code breaks too, and now nothing tells you when. |
| "Me reviso yo mismo, con cuidado" | You share the blind spot that produced the code. |
| "El suite tarda, corro solo los tests de mi tarea" | That's how a regression ships. |
| "Junto tres tareas en un commit" | You lost the clean rollback point that was the reason for per-task commits. |
| "Dos agentes necesitan el mismo archivo, que se coordinen" | The plan is wrong. Fix the plan, don't coordinate around it. |
| "Está bloqueado pero creo que sé qué quiso decir" | Guessing at a blocker builds the wrong thing confidently. Ask. |

## Red Flags

- An agent choosing its own task
- Running more agents than there are ready tasks
- Two agents in flight whose tasks share a file
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
- [ ] Every completed task has tests that were written before its implementation
- [ ] Every completed task was reviewed by a different agent
- [ ] Every completed task has exactly one commit, containing only its declared files
- [ ] Each task file was written only by its own agent
- [ ] No shared state, log or board file was created
- [ ] The full suite and the build are green at the end
- [ ] Notifications fired per task and at plan completion
- [ ] Nothing on the "puntos de parada obligatoria" list shipped without sign-off
- [ ] Blockers were escalated, not worked around
