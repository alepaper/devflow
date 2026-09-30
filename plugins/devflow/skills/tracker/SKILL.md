---
name: tracker
argument-hint: "[off | nombre-del-plan]"
description: Decides and manages where tasks are recorded — Linear issues or local files under docs/plans/<plan>/ — and keeps them in sync with the execution state. Sets up Linear on demand and migrates existing file-based tasks into it without losing progress. Use when the user says "configura Linear", "conecta Linear", "quiero las tareas en Linear", "sincroniza el tablero", when /breakdown asks where to record tasks, or when local state and the tracker have drifted apart.
---

# Tracker — Linear or Files

## Overview

Tasks need to live somewhere a human can see them. Two options, and the choice is
reversible at any moment:

- **Files (default)** — `docs/plans/<slug>/breakdown/T-00N.md`. No setup, no account, works
  offline, versioned with the code.
- **Linear** — one issue per task, dependencies as blocking relations, visible to a team.

Either way, the **task files are the source of truth**. Linear is a mirror for humans.
When they disagree, the task file wins and the issue gets corrected.

**Language:** talk to the user in Spanish. Issue titles and bodies in Spanish.

**Sin herramientas.** La verdad son los archivos de tarea; Linear es el espejo.

`$ARGUMENTS` may be `off` to go back to files only, or a plan name.

## When to Use

- `/breakdown` needs to know where to record tasks
- The user asks to set up, connect, or switch to Linear
- The user asks to sync, or the board looks out of date
- Tasks were created as files and now need to move to Linear

## Files mode (default)

No setup. `/breakdown` writes one file per task using the format in
`../breakdown/references/task-format.md`.

The `estado` frontmatter field is the state. The agent that owns the task updates it and
appends to that task's bitácora — nobody else writes that file. That's what lets a human open
the folder and understand where things stand without running anything.

This is the right default. Never push a user toward Linear who didn't ask — offer it once
during `/breakdown` and move on.

## Linear mode

### Checking availability first

Look for the Linear MCP connector in your available tools. If it isn't there, say so
plainly and stay in files mode:

> No tengo el conector de Linear disponible en esta sesión. Sigo con archivos en
> `docs/plans/<slug>/` y cuando conectes Linear corres `/tracker` y migro todo.

Do not ask the user for an API key and do not try to call the Linear API directly.
The connector handles auth; asking for tokens in chat is the wrong path.

### Setup

Ask for what you actually need, one thing at a time:

1. **Team** — list available teams and let them pick
2. **Project** — an existing project, or create one named after the plan
3. **Label** — default `devflow`, so plan-generated issues are filterable

Save it:

Save it in `plan.md` frontmatter:

```yaml
tracker: linear
linear_team: ENG
linear_project: Portal DS
linear_label: devflow
```

### Creating issues

One issue per task:

| Task field | Linear field |
|---|---|
| `titulo` | Issue title, prefixed with the task id: `T-003 · Un usuario puede iniciar sesión` |
| Qué logra, criterios, tests, verificación, archivos | Issue description (same markdown as the task file) |
| `depende_de` | **Blocking relation** — the dependency blocks this issue |
| `tamano` | Estimate (XS=1, S=2, M=3, L=5) |
| Plan | Project + label |

Keeping `T-00N` in the title is what makes the two systems traceable to each other. Don't
drop it.

Write the Linear id back into the task file's frontmatter immediately:

```yaml
linear: ENG-412
linear_url: https://linear.app/...
```

If issue creation fails halfway, **stop**. A half-created board is worse than no board —
record what succeeded, tell the user which tasks are missing, and let them decide.

### Status mapping

| devflow | Linear |
|---|---|
| `pending` | Todo / Backlog |
| `in_progress` | In Progress |
| `in_review` | In Review |
| `changes_requested` | In Progress (comment with the blockers) |
| `blocked` | Blocked (comment with why) |
| `done` | Done |

The autopilot updates Linear at each transition and posts the review verdict as a
comment. That's what makes the board readable by someone who wasn't in the session.

## Migrating files → Linear

When the user runs `/tracker` on a plan that already has file-based tasks and real
progress:

1. **Read the task files** — their `estado` is the truth
2. **Create one issue per task**, in dependency order so blocking relations can be set
3. **Set each issue to its current status** — a task already `done` is created as Done,
   not Todo. Losing progress in a migration is the failure mode to avoid.
4. **Port the bitácora** as a first comment on each issue, so the history survives
5. **Write the issue ids back** into each task file's frontmatter
6. **Flip the config** to `tracker: "linear"`
7. **Keep the task files.** Don't delete them. They're versioned history and they cost
   nothing. Add a line at the top pointing to the issue.

Confirm the count out loud before starting: *"Voy a crear 7 issues en el proyecto X:
3 en Done, 1 en In Progress, 3 en Todo. ¿Sigo?"*

## Migrating Linear → files

Same in reverse, and equally supported. Nobody should feel locked in.

## Sync drift

When they disagree — someone moved a card by hand, a network call failed mid-run —
the task file wins, because it's what the agents acted on.

But **don't silently overwrite a human's change.** If a Linear issue is Done and the task file
says `in_progress`, that's a person telling you something. Surface it:

> El issue T-004 está en Done en Linear pero localmente sigue `in_progress` y no tiene
> commit asociado. ¿Lo marco como hecho o lo devuelvo a In Progress?

Never bulk-close or delete issues from another plan to make room. Never delete a task
file with unchecked criteria.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Linear es más pro, lo configuro de una" | Setup friction before the first line of code kills momentum. Files work. Offer once. |
| "Creo los issues sin las dependencias, es más rápido" | The dependency graph is the reason the plan exists. Without it the board is a flat list. |
| "Migro todo a Todo y que se re-ejecute" | You just erased completed work from the record. Preserve status. |
| "Borro los archivos de tareas, ya están en Linear" | They're versioned history and they cost nothing. Keep them. |
| "El tablero está desincronizado, lo sobrescribo" | A human may have moved that card deliberately. Ask. |
| "Le pido el API key al usuario por el chat" | Never. Use the connector, or stay in files mode. |

## Red Flags

- Asking for API keys or tokens in conversation
- Creating Linear issues without blocking relations
- Migrating and resetting every task to Todo
- Deleting task files after migration
- Overwriting a manual status change without asking
- Issue titles without the `T-00N` prefix
- Pushing Linear on a user who didn't ask
- Continuing after a partial creation failure without telling the user

## Verification

- [ ] The tracker choice is recorded in `plan.md` frontmatter
- [ ] Every task exists in the chosen tracker, and none is missing
- [ ] Dependencies are blocking relations in Linear, not just text
- [ ] Every Linear issue id is written back into its task file
- [ ] Issue titles carry the `T-00N` prefix
- [ ] After a migration, completed tasks are still completed
- [ ] Task files were preserved, not deleted
- [ ] No credentials were requested or stored anywhere
- [ ] Any drift between state and tracker was surfaced to the user, not silently resolved
