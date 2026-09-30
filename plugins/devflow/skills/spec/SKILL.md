---
name: spec
argument-hint: "describe el proyecto o feature con todo el detalle que tengas: qué, para quién, restricciones"
description: Turns a vague request into an approved, written requirement by interviewing the user one question at a time until intent is unambiguous. Use this at the start of ANY new feature, project, refactor or change — whenever the user says "quiero construir", "necesito una feature", "vamos a hacer X", "levantemos el requerimiento", or hands over an idea that is not yet written down as a spec. Use it whenever you notice yourself about to guess at scope, users, success criteria or constraints. Always run this before /breakdown and before writing any code.
---

# Spec — Requirement Elicitation

## Overview

What people ask for and what they need are different things. The cheapest moment to
close that gap is before any plan or code exists. After code exists, switching costs
are real and the user will rationalize the wrong thing into a "good enough" thing.

This skill produces one artifact: an **approved spec** at
`docs/plans/<plan-slug>/spec.md`. Nothing downstream (`/breakdown`, `/autopilot`) may start
without it, and nothing gets approved without passing Step 7.

**Language:** this file is instructions for you. Talk to the user in Spanish and write
all generated documents in Spanish.

`$ARGUMENTS` may carry the initial topic. If it's empty, ask what they want to build.

## When to Use

- The request is missing any of: **who** it's for, **why** now, what **success** means,
  what the binding **constraint** is
- The ask is conventional rather than specific ("un dashboard", "hazlo más rápido")
- You're tempted to start from assumptions you haven't said out loud
- The user explicitly asks to define, scope, or spec something

**When NOT to use:** unambiguous self-contained changes ("renombra esta variable",
"arregla este typo"), pure questions about how something works, or when a spec for this
work already exists and is still accurate (then go straight to `/breakdown`).

**Do not run this in a non-interactive context** (CI, unattended loop). It needs a live
user. If the request is underspecified and nobody is there to answer, stop and say so.

## The Process

### Step 1 — State a hypothesis with a confidence number

Before asking anything, write your current read in **one sentence** plus an honest
confidence number. Below ~70%, append what's missing.

```
HIPÓTESIS: Quieres que el equipo deje de perder pedidos que llegan por WhatsApp,
           y "CRM" fue la palabra que salió primero.
CONFIANZA: ~30% — falta: quién lo usa, qué pasa hoy cuando se pierde un pedido,
           y cómo sabrías que funcionó.
```

The number forces honesty. If you can't predict the user's answer to the next three
questions you'd ask, the number is too high.

### Step 2 — When the brief arrives complete, restate before asking

Long is good. A detailed description means fewer questions and a higher starting
confidence, and that's legitimate — the stopping condition was never a question count.

But a long brief carries a specific trap: **it feels finished**, so you skip the probing
and build on whatever you misread. Four moves before the first question.

**Read all of it, including attachments.** If they referenced a file, open it. Answering
from the summary and then asking about something the document already covers wastes
their time and tells them you didn't read it.

**Restate, compressed, and ask what you got wrong.** Not a summary that flatters the
brief — the load-bearing parts, in your words:

```
Entendí esto:
- El problema es que los vendedores pierden pedidos de WhatsApp, no que falte un CRM
- Lo abren los vendedores a diario; administración solo consulta
- La restricción dura es que no puede tocar el ERP actual
- Lo que NO está definido: cómo sabrías en 3 meses que funcionó

¿Qué leí mal?
```

A misreading caught here costs one message. Caught after the plan, it costs the plan.

**Audit the brief instead of trusting how complete it feels.** Long descriptions are
reliably thorough about *what* and reliably silent about three things:

| Usually well covered | Usually missing |
|---|---|
| Qué se construye, funcionalidades, pantallas | Por qué ahora, y qué cuesta no hacerlo |
| Cómo debería funcionar | Cómo se sabría que funcionó — una señal observable |
| Casos de uso principales | Qué queda explícitamente fuera |

Go straight at the gaps. Don't re-ask what's already written.

**Contradictions beat new questions.** A long brief usually contains two things that
can't both be true — "tiene que ser simple" next to fourteen features, or a two-week
deadline next to an integration with a system nobody controls. Surfacing one of those is
worth more than three questions:

> Dice que debe salir en dos semanas y que integra con los tres sistemas de permisos,
> que hoy no tienen API. Una de las dos tiene que ceder. ¿Cuál?

**Separate the solution from the requirement.** Detailed briefs usually prescribe a
solution — "un dashboard con filtros por fecha y exportación a Excel". That's an answer
to a problem that isn't written down. Ask for the problem before accepting the shape.

Starting confidence around 70–80% after a thorough brief is honest. Above 90% before
asking anything means you're trusting the document's tone instead of its content.

### Step 3 — One question at a time, each with your guess attached

```
P: ¿Quién va a abrir esto todos los días: tú, los vendedores, o el cliente final?
   SUPONGO: los vendedores, porque hablaste de "perder pedidos" y eso suele ser un
   problema de quien atiende, no de quien administra.
```

Then **stop and wait.** Never send a batch of questions.

- The user reacts to a wrong guess faster than they generate an answer from scratch
- A guess commits you to a position you can be visibly wrong about
- The third question usually depends on the answer to the first

Cover, in roughly this order, skipping what's already clear:

| Area | What you're trying to pin down |
|---|---|
| Usuario | Who touches this, how often, with what skill level |
| Problema | What happens today without it, and what that costs |
| Éxito | The observable signal that it worked — a number or an event |
| Alcance | What is explicitly NOT in this version |
| Restricciones | Deadline, stack, budget, existing systems it must not break |
| Datos | What it reads, what it writes, what must never be lost |
| Casos borde | The two or three failure modes the user already worries about |

### Step 4 — Probe "wants" vs "should want"

When an answer pattern-matches best practice talk ("que sea escalable", "arquitectura
limpia", "moderno") without specifics, ask:

> *"Si no tuvieras que justificárselo a nadie, ¿qué querrías realmente?"*

That single question often does more work than the previous five.

### Step 5 — Stop at ~95%

You're done when you can answer yes to: *can I predict the user's reaction to the next
three questions I would ask?* That's a checkable test, not a vibe.

It has a floor too. If you've gone many rounds and confidence isn't rising, stop and say
so: *"Llevo 8 preguntas y sigo sin poder anticipar tus respuestas. Algo de fondo no está
definido — ¿damos un paso atrás?"*

### Step 6 — Write the draft

Create `docs/plans/<plan-slug>/spec.md` with `estado: borrador`. Derive the slug from the
feature name in kebab-case (`recuperacion-de-contrasena`, not `plan1`). Confirm the slug
with the user if it isn't obvious.

Use the template in `references/spec-template.md`.

Do not ask for approval yet. An unvalidated draft is what Step 7 is for.

### Step 7 — Validate the draft

Three layers, cheapest first. Each one catches a different class of defect.

#### Layer 1 — Falsifiability audit

Go through the draft yourself and apply these tests. They're mechanical, so they're hard
to fool.

| Test | Applied to | Fails when |
|---|---|---|
| **Could two people disagree about whether this was met?** | every success criterion | The answer is yes. "Rápido", "fácil de usar", "escalable" all fail. |
| **Is this a requirement or a solution?** | every item in Alcance | It names a mechanism ("un dashboard con filtros") instead of an outcome. |
| **Who does it, and how would we check?** | every "debe" / "tiene que" | Nobody's named, or there's no way to verify. |
| **Is this term defined anywhere?** | domain nouns | "Usuario autorizado", "sistema activo" used without saying what they mean. |
| **Does this depend on something that exists?** | every integration | It assumes an API, a dataset or a team that isn't confirmed. |

Also check, structurally:

- [ ] **Fuera de alcance is not empty.** Half of all misalignment is silent disagreement
      about what is *not* being built.
- [ ] At least one observable success criterion exists
- [ ] No two statements in the document contradict each other
- [ ] Every open question is listed in Preguntas abiertas rather than quietly resolved

**Anything this audit finds becomes a question for the user, never an answer you supply.**
Filling your own gaps is how a validation layer turns into an invention layer.

#### Layer 2 — Scenario round-trip

This is the strong user-side check, and it replaces "¿te parece bien?" — which reliably
gets a hollow yes.

Instead, hand them **three to five concrete situations** and ask what should happen. The
spec should already answer each one:

```
Antes de aprobar, tres situaciones. Dime qué debería pasar:

1. Alguien sin autorización abre directo la URL de administración de permisos.
2. Un sistema no responde cuando la app le pregunta por su estado.
3. Se revoca el acceso de alguien que ya salió, pero ese sistema no tiene
   revocación programática.
```

Read their answers against the document:

- **The spec already says it** → that area is solid
- **The spec is silent** → a gap, and now you have the answer to write in
- **They hesitate or say "no había pensado en eso"** → a real gap, and the most valuable
  thing this whole step produces
- **Their answer contradicts the spec** → you misunderstood something. Fix the spec, not
  their answer

Pick scenarios at the edges: failure modes, permissions, empty states, and whatever the
Casos borde section is thin on. A scenario everyone answers the same way teaches nothing;
skip the happy path.

#### Layer 3 — Cross-validation by a different agent

Optional, and worth it for anything that will take more than a few days to build.

Invoke the `spec-check` skill. It sends the spec to a different agent — ideally a
different model — which has not sat through the interview and therefore doesn't share
what you inferred without noticing.

The verdict comes back structured. Gaps it finds go back into the interview as questions,
not into the document as your guesses.

### Step 8 — Get an explicit yes

Present the **Resumen** plus what changed after validation, and ask for approval. These
are **not** a yes:

- "Lo que tú creas mejor" → delegation, not decision. Re-ask with two concrete options.
- "Suena bien" → ambiguous. Ask: "¿algo que ajustarías?"
- "Dale" after a vague restate → hollow. Restate concretely and re-confirm.

Mark it approved only after an explicit yes:

```yaml
estado: aprobado
aprobado_en: 2026-09-14
validado_con: [auditoria, escenarios, spec-check]
```

Recording which layers ran matters: a spec approved without the scenario round-trip is a
spec nobody stress-tested, and whoever picks it up later should know that.

### Step 9 — Hand off

Say exactly this, then stop:

> Spec aprobado en `docs/plans/<slug>/spec.md`. El siguiente paso es `/breakdown` para
> partirlo en tareas con dependencias. ¿Seguimos?

Do not start planning in the same turn. `/breakdown` is a separate gate.

## Output

`docs/plans/<plan-slug>/spec.md` — with `estado: aprobado` in frontmatter.

Nothing else. No tasks, no code, no file scaffolding. Those belong to `/breakdown` and
`/autopilot`.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "El pedido ya está claro" | If you can't write the desired outcome in one sentence right now, it isn't. |
| "Preguntar tanto le hace perder tiempo" | 6 questions cost minutes. Building the wrong thing costs days, and the user pays. |
| "Lo voy resolviendo mientras construyo" | Discovery during implementation is rework at 10x the price. |
| "Dijo 'lo que tú veas', así que decido yo" | That's delegation, not a decision. Offer two concrete options instead. |
| "Le mando las 6 preguntas de una y ahorramos vueltas" | Batches get skim-read. You'll get 6 shallow answers instead of 3 real ones. |
| "Lo releí y está completo" | You're checking your own work against your own understanding. That's what Layer 3 is for. |
| "Ese hueco lo puedo inferir del contexto" | Then write it as a question. An inferred requirement is an invented one. |
| "Ya aprobó, no hace falta validar" | An approval on an unvalidated draft is an approval of whatever you misread. |
| "Ya hablamos suficiente, entendí" | Test it: can you predict their next three answers? If not, you haven't. |
| "Me mandó todo escrito, no hace falta preguntar" | Long briefs cover *what* and skip *why*, *éxito* and *fuera de alcance*. Go at those. |
| "El documento es detallado, arranco en 90%" | You're trusting its tone, not its content. Restate first and let them correct you. |

## Red Flags

- Three or more questions in one message — that's a survey, not an interview
- A question sent without your guess attached
- Accepting "lo que tú creas" as a final answer
- Jumping past a long brief with "ya está todo claro" and no restate
- Asking about something the brief already answered
- Confidence above 90% before asking a single question
- Accepting a prescribed solution without finding the problem underneath
- Writing `spec.md` before the user confirmed the restate
- A confidence number under 70% with no reason attached
- Missing "Fuera de alcance" — half of all misalignment is silent disagreement about
  what is *not* being built
- Asking for approval on a draft that skipped Step 7
- Filling a gap the audit found with your own answer instead of asking
- Scenarios that only cover the happy path
- Marking `estado: aprobado` without `validado_con`
- Starting to plan or code in the same turn the spec got approved

## Verification

- [ ] First turn contained a hypothesis with a confidence number
- [ ] With a long brief: everything was read, restated compressed, and "¿qué leí mal?" asked
- [ ] Any contradiction inside the brief was surfaced before new questions
- [ ] No question re-asked something the brief already answered
- [ ] Questions were asked one at a time, each with a guess attached
- [ ] At least one "¿qué querrías realmente?" probe ran on any buzzword answer
- [ ] The spec has: Resumen, Usuario, Problema, Éxito medible, Alcance, Fuera de alcance,
      Restricciones, Casos borde, Preguntas abiertas
- [ ] "Fuera de alcance" is non-empty
- [ ] Success criteria are observable — a number, an event, or a user-visible behavior
- [ ] Every success criterion survives "could two people disagree?"
- [ ] Nothing in Alcance is a solution wearing a requirement's clothes
- [ ] "Fuera de alcance" is non-empty
- [ ] Three to five edge-case scenarios were run past the user, and their answers are in the document
- [ ] Gaps became questions, never assumptions
- [ ] `validado_con` records which layers actually ran
- [ ] The user gave an explicit yes and `estado: aprobado` is in the frontmatter
- [ ] The file lives at `docs/plans/<slug>/spec.md` and nowhere else
- [ ] You stopped and handed off to `/breakdown` instead of continuing
