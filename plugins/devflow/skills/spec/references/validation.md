# Validación del spec

Las tres capas en detalle.

## Layer 1 — Falsifiability audit

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

## Layer 2 — Scenario round-trip

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

## Layer 3 — Cross-validation by a different agent

Optional, and worth it for anything that will take more than a few days to build.

Invoke the `spec-check` skill. It sends the spec to a different agent — ideally a
different model — which has not sat through the interview and therefore doesn't share
what you inferred without noticing.

The verdict comes back structured. Gaps it finds go back into the interview as questions,
not into the document as your guesses.

