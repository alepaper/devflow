# T-000, la tarea base

Detalle de qué verifica T-000 y cómo se cierra.

## Two categories, and they behave oppositely

**Versioned — T-000 creates and commits these. Every worktree gets them for free:**

| Artefacto | Qué verificar |
|---|---|
| Repositorio git | Inicializado y **con al menos un commit** — `git worktree add` falla en un repo sin commits |
| `.gitignore` | Ignora dependencias (`node_modules`, `.venv`, `vendor`), artefactos de build, secretos (`.env`), y archivos de editor y sistema |
| `.env.example` | **Toda** variable que el código o la suite lee, con valores de ejemplo no secretos |
| Manifiestos y lockfiles | `package.json` + `package-lock.json`, `pyproject.toml` + `uv.lock`, etc. El lockfile se commitea |
| Configuración | Linter, formateador, `tsconfig`/`pyproject`, runner de tests |
| Un test trivial que pasa | Prueba que el runner está realmente conectado |

**No versionado — `cmd_setup` los materializa, en cada worktree, cada vez:**

`node_modules`, `.venv`, `vendor`, el `.env` real copiado de `.env.example`, cachés y
artefactos de build.

Estos **no pueden ser el producto de una tarea**: están en `.gitignore`, así que no queda
nada commiteado y el siguiente worktree no los tendría. El trabajo de T-000 no es
instalarlos — es **hacer que `cmd_setup` exista y funcione**.

## The acceptance criterion that actually proves it

One check subsumes every item above:

```bash
git clone <repo> /tmp/verificacion-base && cd /tmp/verificacion-base
<cmd_setup>
<cmd_test>      # verde
<cmd_build>     # sin errores
```

A fresh clone is exactly what a worktree is, minus the shared git directory. If this
passes, every worktree will work. If it doesn't, none will, and you'll debug it N times
in parallel instead of once.

Write it as T-000's criteria verbatim, with the real commands filled in.

## Why `.gitignore` is load-bearing here

It isn't hygiene. If `node_modules` or `.venv` aren't ignored, they get committed, and
then every worktree carries a copy that conflicts on merge — reintroducing precisely the
collision worktrees exist to prevent. Check it before anything else.

Same for `.env`: committed secrets are the one defect in this list you can't fix by
deleting the file later.

## Pick `cmd_setup` from the lockfile, not from preference

`cmd_setup` runs once per worktree, so its cost multiplies by the width of the wave.

**The project's lockfile decides the package manager.** Switching managers on an existing
project changes dependency resolution — `pnpm`'s non-flat `node_modules` breaks packages
that rely on npm's hoisting. Preference only applies when there's no lockfile yet, which
means a new project T-000 is bootstrapping.

```bash
command -v pnpm >/dev/null 2>&1 && echo pnpm || echo npm
command -v uv   >/dev/null 2>&1 && echo uv   || echo pip
```

Prefer `pnpm` and `uv` when the choice is open. Both keep a shared content-addressed
store and hard-link into `node_modules` / `.venv`, so N worktrees cost roughly one copy
on disk instead of N, and every install after the first is near-instant. With `npm`, four
worktrees are four complete dependency trees.

`uv pip install -r requirements.txt` is the one safe swap on an existing project: same
format, same resolution, much faster.

Always use the frozen form — `npm ci`, `pnpm install --frozen-lockfile`, `uv sync
--frozen`. A `cmd_setup` that updates the lockfile does it in every worktree at once and
guarantees a merge conflict in a file no task declared.

If neither manager exists for a stack the project uses, **stop and tell the user what to
install**. There's nothing to work around: without it no worktree can be prepared and the
suite can't run.

Full tables and caching details: `package-managers.md`.

## Dependencies belong to T-000 or to one task

Adding a dependency touches the manifest and the lockfile. Two tasks doing that in
parallel conflict on the lockfile every time. Known dependencies go in T-000; a
dependency discovered later belongs to exactly one task, and that task owns both files.

