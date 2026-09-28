# devflow

Flujo de desarrollo asistido por agentes, en **8 skills**.
Sin instalación, sin dependencias, sin Python. Son archivos markdown.

```
  REQUERIMIENTO      PLAN                    EJECUCIÓN
  ┌──────────┐    ┌──────────────┐    ┌─────────────────────────────┐
  │  /spec   │───▶│    /tasks    │───▶│        /autopilot           │
  │          │    │              │    │  el orquestador reparte     │
  │ entrevista    │ archivos que │    │  TDD · /cross-review        │
  │ 1 pregunta    │ no se solapan│    │  commit por tarea           │
  └──────────┘    └──────────────┘    └─────────────────────────────┘
                        │                          │
                   /tracker (Linear)        /progress · notificaciones
```

## La regla que sostiene todo

> **Dos tareas nunca pueden necesitar el mismo archivo. Si lo necesitan, eso es una
> dependencia.**

Dos agentes no pueden chocar porque dos tareas en paralelo nunca tocan los mismos bytes.
El paralelismo deja de ser algo que uno espera que funcione y pasa a estar garantizado
por la estructura del plan.

**El precio, dicho de frente:** un archivo que tocan cinco tareas serializa las cinco.
Habrá tramos donde solo un agente puede trabajar. Es un plan más lento que no se puede
corromper, y que no necesita ninguna herramienta instalada.

## Instalación

Este repositorio **es** un marketplace de Claude Code. La vía recomendada:

```bash
# parado en la carpeta PADRE de devflow/
claude plugin validate ./devflow
claude plugin marketplace add ./devflow
claude plugin install devflow@alepaper
claude plugin details devflow      # Component inventory → Skills (8)
```

La ruta **tiene que empezar por `./`, `../`, `/` o `~`**. Un nombre pelado devuelve
`Invalid marketplace source format`.

Los comandos quedan como `/devflow:spec`, `/devflow:tasks`, etc. La forma corta `/spec`
también funciona mientras nada más reclame ese nombre.

Instalación manual sin plugin, compartirlo con el equipo, y la advertencia sobre
`--plugin-dir`: **[INSTALAR.md](INSTALAR.md)**.

## Las 8 skills

Cada skill es también su comando. No hay carpeta `commands/`: en Claude Code los comandos
personalizados se fusionaron con las skills, así que `skills/tasks/SKILL.md` ya crea
`/tasks`.

| Skill / comando | Qué hace |
|---|---|
| `/spec` | Entrevista una pregunta a la vez hasta que el requerimiento no tenga ambigüedad. |
| `/spec-check` | Valida el spec con un agente **distinto** al que lo escribió: ambigüedades, criterios no falsables, soluciones disfrazadas de requerimientos, contradicciones. |
| `/tasks` | Parte el spec en tareas verticales, construye la matriz archivo → tareas, y convierte toda colisión en dependencia. |
| `/autopilot` | Reparte tareas a N agentes. TDD obligatorio, revisión por un agente distinto, un commit por tarea. |
| `/cross-review` | Revisa con un agente **distinto** al que escribió el código. Veredicto estructurado. |
| `/progress` | Qué está hecho, qué corre, qué está bloqueado, qué decisión te toca. Solo lectura. |
| `/tracker` | Conecta Linear como espejo y migra lo existente sin perder progreso. |
| `tdd` | Red-green-refactor y depuración por causa raíz. Se activa sola durante la implementación; `user-invocable: false`, así que no aparece en el menú de `/`. |

`/autopilot` se usa por pedazos: `dev`, `test`, `review`, `task T-003`, o `all`.

Guía práctica de uso, con el flujo sesión por sesión y un prompt de arranque:
**[plugins/devflow/USO.md](plugins/devflow/USO.md)**.

## Sobre los nombres

Ninguno pisa un comando nativo de Claude Code. Tres se eligieron por eso:

- `/tasks` en vez de `/plan` — `/plan` es el modo de planificación nativo
- `/cross-review` en vez de `/review` — `/review` es alias del `/code-review` bundled, y
  un skill propio llamado `review` **nunca** se habría ejecutado con ese alias
- `/progress` en vez de `/status`

Instalado como plugin, además quedan namespaced: `/devflow:tasks` funciona siempre,
choque o no.

## Estructura del repositorio

```
devflow/                          ← raíz del marketplace
├── .claude-plugin/
│   └── marketplace.json          # nombre del marketplace: alepaper
└── plugins/
    └── devflow/                  ← el plugin
        ├── .claude-plugin/plugin.json
        ├── skills/               # las 8 skills
        └── USO.md
```

## Estructura que genera

```
docs/plans/<nombre-del-plan>/
├── spec.md          # requerimiento aprobado
├── plan.md          # decisiones, matriz de archivos, olas, comandos, revisor
└── tasks/
    ├── T-001.md     # estado + bitácora adentro
    └── T-002.md
```

**Cada archivo de tarea es su propio estado.** Lo escribe únicamente el agente asignado a
esa tarea. No hay `state.json`, ni `log.md`, ni tablero compartido — serían archivos que
varios agentes escriben, justo lo que la regla prohíbe.

## Las tres reglas que no se negocian

1. **Ningún código cuenta como terminado sin tests escritos antes.**
2. **Ningún agente aprueba su propio código.** Se revisa con un subagente de contexto
   limpio o, mejor, con otro modelo (codex, gemini).
3. **Ningún agente elige su tarea.** El orquestador reparte. Si cada agente eligiera, dos
   podrían leer el tablero en el mismo instante y tomar la misma tarea.

## Configuración

Todo vive en el frontmatter de `plan.md`, escrito una vez por `/tasks`:

```yaml
tracker: archivos              # archivos | linear
cmd_test: npm test
cmd_build: npm run build
cmd_lint: npm run lint
reviewer: codex exec --skip-git-repo-check -    # o: subagente
webhook:                       # opcional, Slack/Discord
```

## Pendiente

Despliegue. El flujo termina en código revisado y commiteado; publicar a producción
todavía es manual.
