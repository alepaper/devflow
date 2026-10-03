# Plantilla de plan

Guarda esto en `docs/plans/<slug>/plan.md`.

```markdown
---
plan: <slug>
titulo: <Nombre legible>
estado: borrador         # borrador | aprobado
tracker: archivos        # archivos | linear
agentes_recomendados: 2
# comandos reales del proyecto, detectados en el reconocimiento
cmd_test: npm test
cmd_build: npm run build
cmd_lint: npm run lint
# preparar un worktree recién creado: sin esto la suite no corre ahí.
# Lo decide el lockfile del proyecto, no la preferencia:
#   pnpm-lock.yaml    -> pnpm install --frozen-lockfile
#   package-lock.json -> npm ci --prefer-offline
#   uv.lock           -> uv sync --frozen
#   requirements.txt  -> uv pip install -r requirements.txt (o pip)
cmd_setup: pnpm install --frozen-lockfile
# archivos ignorados que la suite necesita y hay que copiar a cada worktree
worktree_files: [.env]
rama_integracion: devflow/<slug>
# modelos: el de planeación es recomendación (lo fija /model), el de
# implementación lo usa devflow al despachar subagentes
modelo_planeacion: claude-opus-4-6
modelo_implementacion: sonnet
effort_implementacion:        # solo si el modelo declara soportar effort
# revisor: un CLI externo, o la palabra "subagente"
reviewer: codex exec --skip-git-repo-check -
webhook:                 # opcional, Slack/Discord
---

# Plan: <Título>

## Resumen
Un párrafo: qué se construye y cómo está partido.

## Decisiones de arquitectura
Lo que se decidió y por qué. Esto es lo que no cabe en un ticket.

| Decisión | Alternativa descartada | Por qué |
|---|---|---|
| | | |

## Contratos compartidos
Tipos, esquemas o formas de API que más de una tarea necesita. Cada uno debe ser una
tarea propia, aguas arriba de quienes lo consumen.

- `T-001` define `Usuario` y el esquema de sesión → lo consumen T-002, T-003

## Base del proyecto (T-000)
Qué falta hoy del cimiento. En un repo maduro, casi todo marcado como presente.

| Elemento | Estado | Lo arregla |
|---|---|---|
| Repositorio git con al menos un commit | presente / falta | T-000 |
| `.gitignore` cubre dependencias, build y secretos | | |
| `.env.example` con todas las variables de la suite | | |
| Manifiestos y lockfiles commiteados | | |
| Configuración de linter, formateador y runner | | |
| Un test trivial que pasa | | |

Criterio que cierra T-000, con los comandos reales:

```bash
git clone <repo> /tmp/verificacion-base && cd /tmp/verificacion-base
<cmd_setup> && <cmd_test> && <cmd_build>
```

## Inventario de afirmaciones
Obligatorio cuando el cambio revierte o redefine algo. Qué se afirma hoy que va a dejar
de ser cierto, dónde se afirma, y qué tarea lo actualiza. Toda fila necesita tarea: una
superficie sin dueño es un plan incompleto, no una tarea de documentación para después.

| Afirmación que cambia | Dónde se afirma hoy | Tarea |
|---|---|---|
| | | |

## Matriz de archivos
La evidencia de que el plan es seguro en paralelo. **Ninguna fila puede tener dos tareas
de la misma ola.** Si la tiene, se parte el archivo, se extrae una tarea aguas arriba, o
se encadenan.

| Archivo | Tareas que lo tocan |
|---|---|
| `src/...` | T-001 |

## Mapa de olas
Calculado a mano y verificado contra la matriz. Todo lo de una ola corre en paralelo.

| Ola | Tareas | Agentes útiles |
|---|---|---|
| 1 | T-001 | 1 |
| 2 | T-002, T-003 | 2 |
| 3 | T-004 | 1 |

**Agentes recomendados: 2** (el ancho de la ola más ancha, con tope de 4).

## Índice de tareas

| ID | Título | Tamaño | Depende de | Estado |
|---|---|---|---|---|
| T-001 | | M | — | pending |

En modo Linear, agrega la columna de enlace al issue.

## Riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| | Alto/Medio/Bajo | |

## Puntos de parada obligatoria
Cosas que el autopilot NO puede decidir solo. Si una tarea toca alguno, para y pregunta.

- Migraciones destructivas de datos
- Cambios de autenticación o permisos
- Pagos, cobros o dinero
- Borrado de datos de usuarios
- Cualquier cosa que no se pueda revertir con `git revert`

## Preguntas abiertas
- [ ] <pregunta que necesita decisión humana>
```
