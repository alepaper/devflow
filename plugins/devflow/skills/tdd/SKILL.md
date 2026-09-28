---
name: tdd
user-invocable: false
description: Enforces the red-green-refactor loop — a failing test exists before any implementation, the minimum code makes it pass, then refactoring happens under a green suite. Also covers systematic root-cause debugging when a test or build breaks. Use whenever implementing any behavior, fixing any bug, changing existing functionality, or when a test fails, a build breaks, or something that worked yesterday stopped working. This is mandatory inside /autopilot — no task counts as done without tests written first.
---

# TDD — Red, Green, Refactor

## Overview

A test written after the implementation tests what the code *does*. A test written before
it tests what the code *should do*. That difference is the entire value.

The loop is three steps and the order is not negotiable:

**RED** — write a test for behavior that doesn't exist. Run it. Watch it fail.
**GREEN** — write the least code that makes it pass.
**REFACTOR** — clean it up with the tests holding the line.

**Language:** talk to the user in Spanish. Test names in the project's existing language
and convention.

## When to Use

Always, when writing or changing behavior. Specifically:

- Implementing any task under `/autopilot`
- Fixing a bug — the reproduction *is* the first test
- Changing existing behavior — the old test should break first, deliberately
- A test fails, a build breaks, behavior doesn't match expectations

**When NOT to use:** pure formatting, renames handled by tooling, config-only changes
with no logic, throwaway exploration you will delete.

## The Loop

### RED — the failing test comes first

Write the test. Run it. Confirm two things:

1. **It fails.** A test that passes before the code exists is testing nothing.
2. **It fails for the right reason.** "Function not defined" is a correct RED.
   "Cannot read property of undefined in the test setup" is a broken test, not a RED.

This step is where people cheat, and it's the step that carries all the value. Skipping
it means you never learn whether the test can detect the absence of the feature.

Test the **behavior**, not the implementation:

```
✗ llama a validarEmail() y luego a guardarUsuario()     ← acopla al cómo
✓ un registro con email inválido no crea un usuario     ← describe el qué
```

The first breaks when you refactor. The second survives.

### GREEN — least code possible

Only enough to pass. No speculative abstraction, no "ya que estoy aquí". If you want to
build more, that's a separate task with its own test.

Hardcoding a return value to get green is legitimate. The next test forces the
generalization. That's the method working, not a shortcut.

### REFACTOR — with the net up

Now improve names, remove duplication, extract functions. Run the tests after each move.
Behavior must not change; if a test goes red, the refactor was wrong — revert, don't
"fix" the test.

## What to test

| Test this | Not this |
|---|---|
| Public behavior and contracts | Private helpers directly |
| Edge cases: empty, null, zero, boundary, max | Getters and setters with no logic |
| Error paths and failure modes | Framework or library internals |
| The specific bug you're fixing | Implementation details that will change |
| The acceptance criteria from the task | Mock interactions as an end in themselves |

**Every acceptance criterion in the task needs at least one test.** That mapping is what
makes review objective: the reviewer checks criteria against tests.

## Naming

A test name states behavior and expectation, so a red run tells you what broke without
opening the file.

```
✗ test_login
✗ test_login_2
✓ login_con_password_incorrecta_devuelve_401
✓ sesion_expirada_es_rechazada_al_acceder_a_ruta_protegida
```

## Bug fixing is TDD

1. **Reproduce it as a failing test** before touching any code. If you can't, you don't
   understand the bug yet.
2. Fix it. The test goes green.
3. Keep the test. It's now a regression guard for exactly this bug.

A fix without a test is a fix that will be undone by someone who doesn't know it existed.

## When something breaks — debug systematically

Do not guess. Guessing changes three things at once and teaches you nothing.

1. **Read the actual error.** The whole message, the whole stack trace. Not the summary
   you assume it says.
2. **Reproduce reliably.** An intermittent bug you can't trigger on demand isn't ready to
   be fixed.
3. **Form one hypothesis** about the root cause and state it out loud.
4. **Test that hypothesis with one change.** One. If you change three things and it
   works, you've learned nothing about which mattered.
5. **Fix the cause, not the symptom.** Adding a null check where the null shouldn't exist
   is hiding a bug, not fixing it.
6. **Add the regression test.**

After three failed hypotheses, stop and widen: is the assumption underneath all three
wrong? Say so rather than trying a fourth variation of the same idea.

Never make a test pass by weakening it. Deleting an assertion, adding a skip, loosening a
comparison, wrapping in try/except to swallow the failure — all of these are lying about
the state of the system. If a test is genuinely wrong, say why explicitly and get
agreement before changing it.

## Coverage

Coverage is a smoke detector, not a goal. 100% coverage of trivial code with no edge
cases tested is worse than 70% that covers every failure path.

Care about: every acceptance criterion tested, every error path tested, every bug fixed
having its regression test.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Escribo el test después, es lo mismo" | It isn't. After, you write the test that matches what you built, bugs included. |
| "Es demasiado simple para testear" | Simple code breaks too, and now nothing warns you. |
| "El test es obvio que falla, no lo corro" | Then you never verified the test can detect the failure. Run it. |
| "Lo hago manual, es más rápido" | Once. On the twentieth run it's slower, and it doesn't run in CI. |
| "Ajusto el test para que pase" | You just deleted the evidence that something is broken. |
| "Ya sé qué es, lo arreglo directo" | If you knew, you could write the failing test first. Write it. |
| "Agrego un try/except y listo" | You hid the bug. It will come back somewhere less visible. |
| "Este mock ya prueba suficiente" | A mock proves your mock works. Test the real behavior. |

## Red Flags

- Implementation written before its test exists
- A test that has never been observed failing
- A test that passes on an empty implementation
- `skip`, `only`, or commented-out assertions in committed code
- Assertions removed or loosened to get green
- Test names that describe methods instead of behaviors
- A bug fixed without a regression test
- Three or more things changed between test runs while debugging
- try/except added around the symptom instead of fixing the cause
- Tests that break every time you refactor without changing behavior

## Verification

- [ ] Every test was observed failing before its implementation existed
- [ ] Each failure was for the intended reason, not a setup error
- [ ] Each acceptance criterion in the task maps to at least one test
- [ ] Tests describe behavior, not internals
- [ ] Error paths and edge cases are covered, not just the happy path
- [ ] Any bug fixed has a regression test that fails without the fix
- [ ] No test was weakened, skipped or deleted to reach green
- [ ] The full suite passes, not only the focused tests
- [ ] The build compiles
