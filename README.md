# devflow

Plugin de Claude Code para desarrollo asistido por agentes. Ocho skills que cubren el
ciclo desde el levantamiento del requerimiento hasta código revisado y commiteado.

```
/spec → /spec-check → /breakdown → /autopilot → /progress
         validación    plan     ejecución    estado
```

Los artefactos son markdown bajo `docs/plans/<plan>/`. No hay servicio, base de datos ni
runtime adicional.

---

## Requisitos

| Requisito | Necesidad |
|---|---|
| Claude Code | Obligatorio |
| git | Obligatorio — `/autopilot` hace un commit por tarea |
| `pnpm` / `uv` | Recomendados cuando el proyecto aún no tiene lockfile. Si no están, se usa `npm` / `pip`. Sin ninguno de los dos para una pila en uso, `/breakdown` para y pide instalarlo |
| CLI de revisión externo (`codex`, `gemini`) | Opcional. Sin él, `/cross-review` y `/spec-check` usan un subagente de Claude con contexto limpio |
| Cuenta de [Linear](https://linear.app/) | Opcional. Sin ella, las tareas viven en archivos |

---

## Instalación

Tres vías. La primera es la recomendada.

### 1. Desde GitHub

```bash
claude plugin marketplace add alepaper/devflow
claude plugin install devflow@alepaper
```

`alepaper/devflow` es el repositorio; `alepaper` es el nombre del marketplace declarado
en `marketplace.json`. El id de instalación es siempre `<plugin>@<marketplace>`.

Por defecto la instalación es de ámbito `user` y aplica a todos tus proyectos. Para
fijarlo a un repositorio concreto:

```bash
claude plugin install devflow@alepaper --scope project
```

### 2. Como marketplace local

Útil para trabajar sobre las skills sin publicar cambios.

```bash
git clone https://github.com/alepaper/devflow.git
# desde la carpeta PADRE de devflow/
claude plugin validate ./devflow
claude plugin marketplace add ./devflow
claude plugin install devflow@alepaper
```

Con fuente local y ruta relativa, Claude Code lee los archivos directamente del
directorio clonado. Editas una skill y aplicas el cambio con `/reload-plugins` dentro de
la sesión, sin reinstalar ni subir la versión.

La ruta debe empezar por `./`, `../`, `/` o `~`. Un nombre sin prefijo devuelve
`Invalid marketplace source format`.

### 3. Como skills independientes

Sin plugin. Copia los directorios de skills a tu carpeta personal de Claude Code.

```bash
./install.sh
```

En Windows (PowerShell):

```powershell
$dest = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\plugins\devflow\skills\* $dest -Recurse -Force
```

Los comandos quedan sin prefijo (`/spec`, `/breakdown`). Pierdes `/reload-plugins`, las
actualizaciones por marketplace y el namespace que evita choques de nombres.

### Verificación

```bash
claude plugin list                 # devflow@alepaper  Status: ✔ enabled
claude plugin details devflow      # Component inventory → Skills (8)
```

Si reporta `Skills (0)`, el plugin no cargó aunque la instalación haya salido bien.

Instalado como plugin, los comandos quedan namespaced: `/devflow:spec`,
`/devflow:tasks`. La forma corta `/spec` funciona mientras ningún otro comando reclame
ese nombre.

### Errores comunes

| Mensaje | Causa | Solución |
|---|---|---|
| `Invalid marketplace source format` | La fuente no es `owner/repo`, una URL, ni una ruta que empiece por `./`, `../`, `/` o `~` | `alepaper/devflow` o `./devflow` |
| `Path does not exist: <ruta>` | El formato es correcto, la carpeta no está ahí | Corre el comando desde la carpeta padre |
| `Marketplace file not found at <ruta>/.claude-plugin/marketplace.json` | Apuntaste a la carpeta equivocada | La raíz es la que contiene `.claude-plugin/`, no `plugins/devflow` |
| `Plugin "devflow" not found in marketplace "alepaper"` | Catálogo local desactualizado | `claude plugin marketplace update alepaper` |
| Instaló pero los comandos no aparecen | Instalaste durante una sesión activa | `/reload-plugins` |
| `Skills (0)` en `plugin details` | Usaste `--plugin-dir` apuntando a la raíz del marketplace | Apunta a `./devflow/plugins/devflow`, o usa la vía 1 |

---

## Actualización

### Instalado desde GitHub

Primero sube los cambios al repositorio, **incluyendo el campo `version` de
`plugins/devflow/.claude-plugin/plugin.json`**. Luego:

```bash
claude plugin marketplace update alepaper   # refresca el catálogo
claude plugin update devflow@alepaper       # reinstala la versión nueva
```

Dentro de una sesión activa, aplica el cambio sin reiniciar:

```
/reload-plugins
```

**`claude plugin update` compara el string `version`.** Si subes archivos nuevos sin
subir la versión, responde `already at the latest version` y sigue sirviendo el caché
anterior. Es la causa más común de "actualicé y no cambió nada".

Verifica contra la versión, no contra el mensaje de éxito:

```bash
claude plugin details devflow      # versión esperada + Skills (8)
```

### Actualización automática

Los marketplaces de terceros traen la auto-actualización desactivada. Se enciende con el
toggle *Enable auto-update* en `/plugin` → Marketplaces, o declarándolo en
`~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "alepaper": {
      "source": { "source": "github", "repo": "alepaper/devflow" },
      "autoUpdate": true
    }
  }
}
```

Hay reportes de que `autoUpdate` refresca el catálogo pero no reinstala los plugins. Si
lo activas, confirma con `claude plugin details devflow` en vez de asumir que estás al
día.

### Instalado como marketplace local

Claude Code lee los archivos directamente del directorio clonado, así que basta con traer
los cambios y recargar:

```bash
git pull
```

```
/reload-plugins
```

### Instalado como skills independientes

Vuelve a copiar. `install.sh` reemplaza cada directorio de skill, así que un rename como
`tasks` → `breakdown` deja el directorio viejo atrás:

```bash
git pull && ./install.sh
rm -rf ~/.claude/skills/tasks     # limpiar skills renombradas o eliminadas
```

---

## Desinstalación

Desinstalar el plugin y conservar el marketplace registrado:

```bash
claude plugin uninstall devflow@alepaper
```

Quitar el marketplace, lo que desinstala también sus plugins:

```bash
claude plugin marketplace remove alepaper
```

Si instalaste como skills independientes:

```bash
rm -rf ~/.claude/skills/{spec,spec-check,breakdown,autopilot,cross-review,progress,tracker,tdd}
```

Ninguna de las tres borra los artefactos de tus proyectos. `docs/plans/` queda intacto,
versionado con tu código.

Para desactivar sin desinstalar:

```bash
claude plugin disable devflow@alepaper
```

---

## Skills

| Comando | Función |
|---|---|
| `/spec` | Entrevista una pregunta a la vez hasta que el requerimiento no tenga ambigüedad. Valida el borrador en tres capas antes de pedir aprobación. Produce `spec.md`. |
| `/spec-check` | Envía el spec a un agente distinto del que lo escribió. Detecta ambigüedades, criterios no falsables, soluciones disfrazadas de requerimiento, contradicciones y dependencias no confirmadas. Veredicto: `LISTO`, `HUECOS` o `BLOQUEADO`. |
| `/breakdown` | Parte el spec en tareas verticales. Si hay varios specs, los lista para que elijas uno, varios o todos. Inventaría qué documentos y plantillas afirman hoy lo que va a cambiar, construye la matriz archivo → tareas y convierte cada colisión en dependencia. Produce `plan.md` y un archivo por tarea. |
| `/autopilot` | Reparte tareas a N agentes, con TDD obligatorio, revisión por un agente distinto y un commit por tarea. Argumentos: `dev`, `test`, `review`, `task T-00N`, `all`. |
| `/cross-review` | Revisa código con un agente distinto del que lo escribió. Veredicto: `APPROVED`, `CHANGES_REQUESTED` o `BLOCKED`. |
| `/progress` | Estado del plan: hecho, en vuelo, listo, bloqueado, y la próxima decisión pendiente. Solo lectura. |
| `/tracker` | Registra las tareas en Linear y migra planes existentes preservando estado. Reversible. |
| `tdd` | Red-green-refactor y depuración por causa raíz. `user-invocable: false`: la carga Claude durante la implementación y no aparece en el menú de `/`. |

Tres nombres difieren del obvio porque el obvio está tomado por Claude Code: `/breakdown` (no `/plan` ni `/tasks`), `/cross-review` (no `/review`), `/progress` (no `/status`).

Referencia extendida con el flujo sesión por sesión:
[plugins/devflow/USO.md](plugins/devflow/USO.md).

---

## Ejemplo de uso

Recorrido completo sobre una feature pequeña: recuperación de contraseña por correo.

### Paso 0 — Verificar el revisor

Antes de la primera tarea, no después de cinco:

```bash
printf 'Responde únicamente con este bloque, sin nada más:\n\nVERDICT: APPROVED\nBLOCKERS:\nNITS:\n' \
  | codex exec --skip-git-repo-check -
```

Debe imprimir `VERDICT: APPROVED`. Si no, corrige el comando antes de seguir.

Verifica también que el árbol esté limpio: `/autopilot` hace un commit por tarea y los
cambios sueltos se colarían dentro.

### Paso 1 — Levantar el requerimiento

Prompt inicial:

```
/spec recuperación de contraseña por correo

Contexto del proyecto:
- Stack: Node + Express + PostgreSQL, frontend en React
- Tests: npm test
- Build: npm run build
- Reviso con: codex
```

Las cuatro últimas líneas evitan el reconocimiento y quedan guardadas en `plan.md` para
que `/autopilot` las use después.

Claude responde con una hipótesis, un número de confianza, y **una** pregunta:

```
HIPÓTESIS: Quieres que la gente recupere su cuenta sin escribirle a soporte.
CONFIANZA: ~35% — falta: qué canal usan hoy, cuánto dura el token, qué pasa si
           el correo no llega.

P: ¿El correo sale de tu sistema o de un proveedor tipo SendGrid?
   SUPONGO: un proveedor, porque montar entregabilidad propia rara vez vale la pena
   para esto.
```

Responde corto. Sigue preguntando de a una hasta poder anticipar tus siguientes tres
respuestas. Puedes entregarle el requerimiento completo desde el principio: con una
descripción larga primero te devuelve lo que entendió y te pide que lo corrijas.

Antes de pedir aprobación valida el borrador y te entrega escenarios concretos:

```
Antes de aprobar, tres situaciones. Dime qué debería pasar:

1. Alguien pide recuperación con un correo que no existe en el sistema.
2. El token expira mientras el usuario tiene el formulario abierto.
3. Alguien pide recuperación cinco veces en un minuto.
```

Si dudas en alguna, ahí hay un hueco. Las respuestas quedan escritas en el spec.

Resultado: `docs/plans/recuperacion-de-contrasena/spec.md` con `estado: aprobado`.

### Paso 2 — Validar con otro agente

```
/spec-check
```

Manda el spec a codex **sin la conversación**, porque ese agente debe ver solo lo que
verá quien construya. Devuelve `LISTO`, `HUECOS` o `BLOQUEADO`.

`HUECOS` es el resultado normal. Cada hueco vuelve como pregunta para ti, no como algo
que Claude rellene.

### Paso 3 — Partir en tareas

```
/breakdown
```

Si hay varios specs en `docs/plans/`, primero los lista para que elijas:

```
Encontré 4 specs en docs/plans/:

  #  Plan                        Estado     Validación      Plan
  1  recuperacion-de-contrasena  aprobado   spec-check ✔    —
  2  portal-ds                   aprobado   sin validar     —
  3  notificaciones-push         aprobado   spec-check ✔    ya planeado (7 tareas)
  4  reportes-mensuales          borrador   —               —

¿Cuál planeo? Puedes decirme un número, varios (1,2), o "todos".
```

Si eliges varios, la matriz de archivos se construye **sobre todos a la vez**: dos planes
en paralelo pueden chocar en un archivo igual que dos tareas del mismo plan, y una matriz
por plan no lo vería.

Luego construye la matriz, que es donde aparecen las colisiones:

```
| Archivo                    | Tareas        |
| src/rutas/index.ts         | T-002, T-003   ← COLISIÓN
```

Dos tareas necesitan el mismo archivo. Se resuelve partiendo el archivo, extrayendo una
tarea aguas arriba que haga todas sus ediciones, o encadenando las tareas. Claude
propone, tú decides.

Luego muestra las olas y el número de agentes que sirve de verdad:

```
Ola 1: T-000                 → 1 agente   (base del proyecto, siempre sola)
Ola 2: T-001                 → 1 agente
Ola 3: T-002, T-003          → 2 agentes
Ola 4: T-004                 → 1 agente

Agentes recomendados: 2
```

Revisa la matriz antes de aprobar: es la evidencia de que el plan es seguro en paralelo.

### Paso 4 — Ejecutar

```
/autopilot
```

Pregunta con cuántos agentes arrancar y reparte tareas por nombre. Por cada una: tests
que fallan primero, código mínimo, refactor, suite completa, build, commit solo de los
archivos declarados, revisión por otro agente, aprobación.

Por pedazos:

```
/autopilot dev            implementa y deja todo en in_review
/autopilot review         solo revisa lo que espera
/autopilot task T-003     solo esa tarea
```

Para la primera corrida en un proyecto nuevo, arranca con una tarea y un agente:

```
/autopilot task T-001
```

### Paso 5 — Consultar estado

```
/progress
```

Solo lectura. Qué está hecho, qué está en vuelo y con qué agente, qué espera y por quién,
y cuál es la próxima decisión que te toca.

---

## Linear (opcional)

[Linear](https://linear.app/) sirve como tablero visual de las tareas del plan. Es
opcional: por defecto las tareas viven en archivos markdown dentro de
`docs/plans/<plan>/tasks/`, y el flujo funciona igual sin cuenta.

### Configuración

Requiere el conector de Linear activo en la sesión de Claude Code. devflow no pide ni
almacena API keys.

```
/tracker
```

Pregunta de a uno: equipo, proyecto (existente o nuevo con el nombre del plan) y
etiqueta. La elección queda en el frontmatter de `plan.md`:

```yaml
tracker: linear
linear_team: ENG
linear_project: Recuperación de contraseña
linear_label: devflow
```

### Qué hace

- Un issue por tarea, con título prefijado `T-00N ·` para que ambos sistemas sean
  rastreables
- Las dependencias se crean como relaciones de bloqueo reales, no como texto
- `/autopilot` actualiza el estado del issue en cada transición y publica el veredicto de
  revisión como comentario

| Estado en el archivo | Estado en Linear |
|---|---|
| `pending` | Todo / Backlog |
| `in_progress` | In Progress |
| `in_review` | In Review |
| `changes_requested` | In Progress + comentario con los bloqueantes |
| `blocked` | Blocked + comentario con la causa |
| `done` | Done |

### Migración y reversa

Puedes conectarlo después, con el plan a medio ejecutar. La migración preserva el estado:
una tarea en `done` se crea en Done, no en Todo. Los archivos de tarea no se borran.

```
/tracker off
```

Vuelve a solo archivos.

Los archivos de tarea siguen siendo la fuente de verdad: son lo que los agentes leen y
escriben. Linear es el espejo para lectura humana.

---

## Modelo de ejecución

### Inventario de afirmaciones

La matriz garantiza que dos agentes no choquen. No garantiza que el plan cubra todo lo
que el cambio invalida: son dos preguntas distintas.

Antes de repartir archivos, `/breakdown` inventaría qué afirma hoy el comportamiento que
va a cambiar — documentación, plantillas, ejemplos, mensajes de ayuda y error, tests que
codifican la regla vieja, y los propios artefactos del plan. Cada superficie recibe una
tarea dueña.

Aplica a cualquier reversión: un default que cambia, una regla que se invierte, un nombre
que se renombra, una dependencia que se elimina. Los renames y las eliminaciones son los
peores casos, porque dejan atrás cada frase que mencionaba lo anterior y esas frases se
leen como vigentes.

Sin este paso, el texto obsoleto aparece en revisión, que es el lugar caro para
encontrarlo.

### T-000, la base del proyecto

Todo plan arranca con T-000 y todas las demás tareas dependen de ella. Verifica y
completa el cimiento versionado: repositorio git con al menos un commit, `.gitignore` que
cubra dependencias y secretos, `.env.example` con todas las variables que lee la suite,
manifiestos con sus lockfiles, configuración de linter y runner, y un test trivial que
pase.

Lo no versionado — `node_modules`, `.venv`, el `.env` real — no puede ser producto de una
tarea: está ignorado, así que no queda nada commiteado. Eso es `cmd_setup`, y corre en
cada worktree. El trabajo de T-000 es **hacer que `cmd_setup` funcione**.

Cierra con un criterio que subsume a los demás:

```bash
git clone <repo> /tmp/verificacion-base && cd /tmp/verificacion-base
<cmd_setup> && <cmd_test> && <cmd_build>
```

Un clon limpio es lo que es un worktree. Si esto pasa, todos funcionarán; si no, ninguno,
y lo depurarías N veces en paralelo en vez de una.

### Worktrees e integración

Con **dos o más** agentes, cada tarea corre en su propio `git worktree`. Con un solo
agente no hay worktrees: se trabaja directo sobre la rama de integración.

La razón no es evitar que se pisen archivos — eso ya lo cubre la matriz. Es que sin
aislamiento **la compuerta de suite verde del TDD no se puede hacer cumplir**: cuando un
agente corre la suite completa antes de commitear y está roja por el trabajo a medias de
otro, no puede distinguir esa falla de una regresión propia. Le queda esperar —
serializando, así que el paralelismo se pierde igual — o commitear decidiendo que "esos
fallos no son míos", que convierte la compuerta en teatro.

Cada tarea aprobada se integra de inmediato en la rama `devflow/<plan>`, en orden de
dependencia y con la suite completa verde después de cada merge. Al terminar el plan, esa
rama se mergea una sola vez a la rama base.

Un conflicto de merge significa que el plan estaba mal: dos tareas compartían un archivo
que la matriz decía que no. Se escala como defecto de planeación, no se resuelve a mano.

Cada worktree se elimina apenas su tarea se integra, o si queda bloqueada: el peso no es
el checkout sino las dependencias que `cmd_setup` instaló dentro. Al cerrar el plan,
`git worktree list` debe mostrar solo el repositorio principal. Los huérfanos de sesiones
interrumpidas los reporta `/progress` y los limpia `/autopilot` antes de la siguiente ola.

Un merge limpio con la suite roja es un conflicto **semántico** — dos tareas que no
comparten archivo pero cambian el mismo comportamiento. La exclusividad de archivos no
previene eso, y también es condición de parada.

Requiere `cmd_setup` en `plan.md`: un worktree nuevo no tiene `node_modules` ni `.env`, y
sin prepararlo la suite no corre. Su costo se multiplica por el ancho de la ola, así que
el gestor importa: `pnpm` y `uv` mantienen un almacén compartido y enlazan duro, de modo
que N worktrees cuestan ~1 copia en disco; con `npm` o `pip` son N copias. El gestor lo
decide el lockfile del proyecto, no la preferencia — cambiarlo altera la resolución de
dependencias.

### Exclusividad de archivos

> Dos tareas nunca pueden necesitar el mismo archivo. Si lo necesitan, eso es una
> dependencia.

Consecuencia: dos agentes en paralelo nunca escriben los mismos bytes, sin locks ni
coordinación en tiempo de ejecución.

Costo: un archivo que necesitan cinco tareas las serializa. Los planes resultan más
secuenciales, y habrá olas de un solo agente. `/breakdown` reporta el ancho de cada ola como
número recomendado de agentes, con tope de 4.

### Invariantes

1. **Tests antes del código.** Ninguna tarea cuenta como terminada sin tests que se
   observaron fallando antes de la implementación.
2. **Nadie aprueba su propio trabajo.** Ni código ni spec. El revisor es un subagente de
   contexto limpio o, preferiblemente, otro modelo.
3. **Nadie elige su tarea.** El orquestador reparte por nombre. El auto-servicio permite
   que dos agentes lean el tablero en el mismo instante y tomen la misma tarea.
4. **Los agentes en paralelo corren en worktrees separados.** Un worktree por tarea,
   creados desde la rama de integración al empezar la ola.

---

## Artefactos y configuración

```
docs/plans/<plan>/
├── spec.md          # requerimiento aprobado y validado
├── spec-check.md    # veredicto del validador externo
├── plan.md          # decisiones, matriz de archivos, olas, configuración
├── tasks/
│   ├── T-000.md     # base del proyecto
│   ├── T-001.md     # estado en frontmatter + bitácora
│   └── T-002.md
└── reviews/         # prompts y veredictos de cada revisión
```

Cada archivo de tarea tiene un único escritor: el agente asignado a esa tarea. El campo
`estado` de su frontmatter es la fuente de verdad.

**Compatibilidad con proyectos viejos.** Algunos planes creados con versiones anteriores
tienen `breakdown/` en vez de `tasks/`, o `tasks.md` / `breakdown.md` en vez de
`plan.md` — dos renombres de comando arrastraron rutas de artefactos por error. Las
skills los leen igual, y la primera que escriba en el plan los renombra al layout
canónico en un commit aparte. `/progress` lo reporta sin tocar nada, porque es de solo
lectura.

Toda la configuración vive en el frontmatter de `plan.md`, escrito una vez por `/breakdown`:

```yaml
tracker: archivos                               # archivos | linear
cmd_test: npm test
cmd_build: npm run build
cmd_lint: npm run lint
cmd_setup: npm ci                               # preparar un worktree nuevo
worktree_files: [.env]                          # ignorados que la suite necesita
reviewer: codex exec --skip-git-repo-check -    # o: subagente
webhook:                                        # opcional, Slack/Discord
```

---

## Estructura del repositorio

```
devflow/                              # raíz del marketplace
├── .claude-plugin/marketplace.json   # marketplace: alepaper
├── install.sh                        # instalación como skills independientes
└── plugins/devflow/                  # el plugin
    ├── .claude-plugin/plugin.json
    ├── USO.md
    └── skills/                       # las 8 skills
```

---

## Historial de versiones

Decisiones y cambios por versión: [CHANGELOG.md](CHANGELOG.md).

## Limitaciones conocidas

- **Despliegue fuera de alcance.** El flujo termina en código revisado y commiteado.
- **Validación del grafo manual.** `/breakdown` verifica ciclos y dependencias inexistentes
  con un checklist, no con una herramienta.
- **Paralelismo con worktrees poco ejercitado.** El ciclo completo se ha corrido de punta
  a punta, pero con pocos agentes. En un proyecto nuevo, arranca con
  `/autopilot task T-000` y un agente antes de escalar.
- **Conflictos semánticos fuera del alcance de la matriz.** Dos tareas que no comparten
  archivo pueden romper el mismo comportamiento. Se detecta en el merge, no al planear.
