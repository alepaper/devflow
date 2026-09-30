---
name: spec-check
argument-hint: "[ruta al spec]"
description: Validates a written requirement by sending it to a DIFFERENT agent — ideally a different model — which finds ambiguities, unfalsifiable success criteria, solutions disguised as requirements, contradictions, undefined terms and missing failure modes. Returns a structured verdict. Use before approving any spec, before /breakdown, when the user says "valida el spec", "revisa el requerimiento", "¿esto está bien entendido?", or when inheriting a spec someone else wrote. Never let the agent that wrote the spec be the one that validates it.
---

# Spec-check — Validation by a Different Agent

## Overview

The agent that ran the interview cannot validate its own spec. It inferred things it
never wrote down, and every one of those inferences reads as obvious to it. A second
agent that wasn't there sees only what the document actually says — which is exactly the
test that matters, because whoever builds from it will also only see the document.

This produces a **structured verdict**, not prose. Prose without a verdict is a second
opinion, not a gate.

**Language:** talk to the user in Spanish. The prompt and report go in Spanish too.

## When to Use

- A spec draft exists and is about to be approved
- Before `/breakdown`, for anything that will take more than a few days to build
- The user inherited a spec and wants to know if it's buildable
- The user asks to validate, sanity-check or review a requirement

**When NOT to use:** the spec is still being written and half the sections are empty.
Finish the interview first — validating a draft that's knowingly incomplete just
rediscovers what you already know is missing.

## The hard rule

**The validator must not be the agent that wrote the spec.** Two acceptable setups:

| Setup | Strength |
|---|---|
| External CLI, different model (codex, gemini) | **Preferred.** A different model has different blind spots. |
| Claude subagent with clean context | Weaker — same model — but it never saw the interview, which is most of the value. |

Never "re-read it carefully myself". That's the failure this skill exists to prevent.

## The Process

### 1. Assemble the input

The validator has no conversation history. Everything goes in the prompt:

- The full spec, verbatim
- Nothing else. **Do not include the interview transcript or your reasoning.** Those
  contain the inferences you're trying to test. If the spec only makes sense with them,
  that's the finding.

### 2. Build the prompt

Write it to `docs/plans/<slug>/spec-check-prompt.md`:

```markdown
Eres un ingeniero senior que va a construir esto. NO escribiste este documento y no
estuviste en la conversación que lo produjo. Solo tienes el texto.

## El requerimiento
<spec.md completo>

## Qué evaluar

1. AMBIGÜEDAD — ¿Hay algo que dos ingenieros competentes construirían distinto leyendo
   lo mismo? Cita la frase exacta.
2. CRITERIOS DE ÉXITO — ¿Cada uno es falsable? ¿Podrías demostrar objetivamente que NO
   se cumplió? "Rápido", "fácil de usar", "escalable" no son falsables.
3. SOLUCIONES DISFRAZADAS — ¿Algún requerimiento describe un mecanismo en vez de un
   resultado? ("un dashboard con filtros" es una solución; "el equipo puede ver los
   pedidos atrasados sin preguntarle a nadie" es un requerimiento.)
4. CONTRADICCIONES — ¿Hay dos afirmaciones que no pueden ser ambas ciertas? Plazos
   contra alcance, "simple" contra una lista larga, restricciones que se excluyen.
5. TÉRMINOS SIN DEFINIR — ¿Qué sustantivos del dominio se usan sin decir qué significan?
6. MODOS DE FALLA AUSENTES — ¿Qué pasa cuando algo no responde, llega vacío, llega dos
   veces, o el usuario no tiene permiso? ¿El documento lo dice?
7. DEPENDENCIAS NO CONFIRMADAS — ¿Asume que existe una API, un dato, un equipo o un
   acceso que el documento no confirma que exista?
8. FUERA DE ALCANCE — ¿Está vacío o es decorativo? Lo que no se construye importa tanto
   como lo que sí.

## Lo que NO es tu trabajo

No propongas soluciones. No rellenes los huecos que encuentres. No opines sobre
arquitectura ni stack. Tu trabajo es señalar qué no se puede construir sin preguntar.

## Formato de salida OBLIGATORIO

Termina exactamente con este bloque:

VERDICT: LISTO | HUECOS | BLOQUEADO
HUECOS:
- <categoría>: <la frase exacta del documento> → <qué pregunta falta responder>
MENORES:
- <cosas que mejorarían el documento pero no impiden construir>

Usa LISTO solo si un ingeniero podría empezar a planear sin preguntar nada.
Usa BLOQUEADO si el documento asume algo que probablemente no existe.
```

### 3. Run it

```bash
codex exec --skip-git-repo-check - \
  < docs/plans/<slug>/spec-check-prompt.md \
  | tee docs/plans/<slug>/spec-check.md
```

With a subagent instead, give it the prompt file only — not the conversation.

No `VERDICT:` line in the output → re-run once repeating the format requirement. Still
none → treat as BLOQUEADO and tell the user; don't infer what the validator meant.

### 4. Act on the verdict

**LISTO** → record it in the spec frontmatter and continue to approval:

```yaml
validado_con: [auditoria, escenarios, spec-check]
spec_check: LISTO
```

**HUECOS** → this is the normal and useful outcome. Each gap becomes **a question for
the user**, phrased the way the `spec` skill asks: one at a time, with your guess
attached.

> El validador marcó que "usuario autorizado" no está definido en ningún lado.
>
> P: ¿Quién decide que alguien es usuario autorizado — un grupo de Google, un rol en
>    un sistema que ya existe, o una lista dentro de la app?
>    SUPONGO: un grupo de Google, porque ya es donde vive la pertenencia en Melonn.

**Never close a gap with your own answer.** The validator found something the document
doesn't say; inventing what it should say reintroduces exactly the inference the
validation was testing for. If the user says "decide tú", offer two concrete options.

**BLOQUEADO** → the spec assumes something that may not exist. Surface it plainly and
stop. This usually means the work has an external dependency nobody scoped.

### 5. Re-validate after substantial edits

If answering the gaps changed the spec materially, run it again. Cheap, and the second
pass regularly finds something the first round's changes introduced.

Two rounds is normal. A third means the interview didn't go deep enough — go back to
`/spec` rather than grinding on the document.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Lo reviso yo, que conozco el contexto" | That context is the problem. The builder won't have it. |
| "Le paso también la conversación para que entienda" | Then you're testing the conversation, not the document. Send the spec alone. |
| "El hueco es obvio, lo relleno y sigo" | An inferred requirement is an invented one. It becomes a question. |
| "Marcó 8 huecos, es demasiado, tomo los 3 importantes" | You're re-deciding what matters using the judgment that produced the gaps. |
| "Dijo BLOQUEADO pero creo que ese sistema sí tiene API" | "Creo" is the whole finding. Confirm it before planning around it. |
| "Ya lo aprobó el usuario, validar es tarde" | Approval of an unvalidated draft approves whatever was misread. |

## Red Flags

- The spec's author validating it
- The interview transcript included in the prompt
- A validation that produced no `VERDICT:` line
- Gaps closed with assumptions instead of questions
- Cherry-picking which gaps to address
- Proposing architecture or stack — out of scope for this skill
- A spec marked `aprobado` whose `spec_check` says `HUECOS`
- More than two validation rounds without going back to the interview

## Verification

- [ ] The validator was a different agent from the spec's author
- [ ] Only the spec was sent — no transcript, no reasoning
- [ ] A structured verdict came back and was parsed
- [ ] Every gap became a question asked to the user, one at a time
- [ ] No gap was closed with an inferred answer
- [ ] The report is saved at `docs/plans/<slug>/spec-check.md`
- [ ] The verdict is recorded in the spec's frontmatter
- [ ] After material edits, validation ran again
