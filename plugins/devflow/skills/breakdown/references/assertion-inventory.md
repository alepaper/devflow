# Inventario de afirmaciones

Cómo encontrar qué afirma hoy el comportamiento que va a cambiar.

## How to build it

For each behavior the change touches, find **what claims it today** — not what calls it.
A symbol search finds the code; prose that asserts the old rule has no symbol.

Search three ways, because each misses what the others catch:

1. The old **name** (`state.json`, `--plugin-dir`, the old command)
2. The old **concept in prose** ("el estado vive en", "se instala con", "requiere Python")
3. The **inverse claim** — text that says something is impossible, required or absent
   that is about to stop being true

Surfaces worth checking, in rough order of how often they're missed:

| Surface | Why it gets missed |
|---|---|
| README and `docs/` | Everyone assumes someone else updates them |
| Templates and scaffolding | They *generate* the stale text into new files |
| Examples inside documentation | Copy-pasted by users, so wrong examples spread |
| Tests that encode the old rule | They pass, so nothing flags them |
| Help text and error messages | Live in strings, invisible to a symbol search |
| Other prompts, skills or agent instructions | Assert behavior in prose, never in code |
| Comments and changelogs | Nobody greps comments |
| The plan's own artifacts | `spec.md` and the task templates state rules too |

That last row matters: if a rule applies to the system, it applies to the system's own
documents. A plan that changes a rule and leaves its own spec asserting the old one is
inconsistent by construction.

## The output

A table, written into `plan.md`:

| Afirmación que cambia | Dónde se afirma hoy | Tarea |
|---|---|---|
| El estado vive en `state.json` | `README.md` §Artefactos, `USO.md` §3, `skills/autopilot/SKILL.md` | T-004 |
| Se instala con `--plugin-dir` | `README.md` §Instalación, `INSTALAR.md` | T-004 |

**Every surface must have an owning task.** A surface with no task is an incomplete plan,
not a documentation chore for later — "later" means it surfaces in review, which is the
expensive place to find it.

These surfaces then flow into Step 3 as declared files, so the matrix resolves their
collisions like any others. Frequently one documentation task ends up owning several
surfaces; that's fine and usually correct, since they change together and a single writer
keeps them consistent.

## Sizing

Updating documentation is a task with acceptance criteria like any other:

```
- [ ] Ninguna búsqueda de "state.json" devuelve texto que lo presente como vigente
- [ ] Los ejemplos del README corren tal como están escritos
```

A criterion phrased as a search is verifiable, which is what makes the task closeable.

