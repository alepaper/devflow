# Layout del plan y migración de proyectos viejos

## Canónico

```
docs/plans/<slug>/
├── spec.md
├── spec-check.md
├── plan.md
├── tasks/
│   ├── T-000.md
│   └── T-001.md
└── reviews/
```

El directorio se llama `tasks/` porque contiene tareas. `breakdown` es el nombre de la
skill que las produce, no el del artefacto.

## Nombres heredados

Dos renombres de comandos arrastraron por error rutas de artefactos, así que hay
proyectos en circulación con nombres que ya no son los correctos:

| Origen | Directorio de tareas | Documento del plan |
|---|---|---|
| Canónico | `tasks/` | `plan.md` |
| Herencia A (`/plan` → `/tasks`) | `tasks/` ✔ | `tasks.md` ✘ |
| Herencia B (`/tasks` → `/breakdown`) | `breakdown/` ✘ | `breakdown.md` ✘ |

No fueron decisiones de diseño: fueron sustituciones de texto demasiado amplias que
tocaron rutas además de nombres de comando. Un proyecto creado con esas versiones
funciona perfectamente; solo tiene los directorios mal nombrados.

## Resolución al leer

Cualquier skill que abra un plan resuelve en este orden y usa el primero que exista:

| Busca | Luego | Luego |
|---|---|---|
| `tasks/` | `breakdown/` | error: el plan no tiene tareas |
| `plan.md` | `tasks.md` | `breakdown.md` |

Si existen **dos a la vez** — por ejemplo `tasks/` y `breakdown/` — hay una migración a
medias. Para y pregunta: fusionar directorios a ciegas puede perder archivos de tarea.

## Migración

Las skills que escriben en el plan (`breakdown`, `autopilot`, `cross-review`, `tracker`)
migran antes de hacer cualquier otra cosa. `progress` es de solo lectura: detecta,
reporta y no toca nada.

Se hace una vez, es barato y deja el proyecto en el layout canónico:

```bash
cd docs/plans/<slug>

[ -d breakdown ]     && git mv breakdown tasks
[ -f breakdown.md ]  && git mv breakdown.md plan.md
[ -f tasks.md ]      && git mv tasks.md plan.md
```

Si los archivos no están versionados, `git mv` falla y se usa `mv` normal.

### Las referencias internas también

Renombrar los directorios no arregla el texto que los menciona. Dentro de la carpeta del
plan suele haber rutas escritas en `plan.md`, en los archivos de tarea y en los informes
de revisión:

```bash
grep -rln "plans/<slug>/breakdown\|plans/<slug>/tasks\.md" docs/plans/<slug>/
```

Corrige las que aparezcan. Es el mismo inventario de afirmaciones del paso 2b aplicado a
los artefactos del propio plan: renombrar la cosa sin corregir lo que la nombra deja el
proyecto afirmando algo falso.

Si el plan está espejado en Linear, las descripciones de los issues pueden traer la ruta
vieja. Es cosmético, pero vale corregirlo mientras se migra.

### Un solo commit, antes de trabajar

```bash
git commit -m "devflow: migra el plan <slug> al layout canónico (tasks/ + plan.md)"
```

Separado del trabajo del plan. Mezclar un renombre masivo con cambios de código hace
ilegible el diff de ambos.

Avísale al usuario en una línea:

> El plan `<slug>` usaba el layout viejo (`breakdown/`). Lo renombré a `tasks/` y
> actualicé las referencias internas. Commit `a3f9c21`.

### Qué no hacer

- **No migrar durante una ola en vuelo.** Hay agentes con rutas resueltas en su contexto
  y worktrees creados. Espera a que la ola cierre.
- **No fusionar `tasks/` y `breakdown/` automáticamente** si los dos existen.
- **No borrar nada.** Un renombre mueve archivos; no hay motivo para eliminar ninguno.
