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

Para actualizar a una versión nueva:

```bash
claude plugin marketplace update alepaper
claude plugin install devflow@alepaper
```

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
| `/breakdown` | Parte el spec en tareas verticales. Si hay varios specs, los lista para que elijas uno, varios o todos. Construye la matriz archivo → tareas y convierte cada colisión en dependencia. Produce `plan.md` y un archivo por tarea. |
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
Ola 1: T-001                 → 1 agente
Ola 2: T-002, T-003          → 2 agentes
Ola 3: T-004                 → 1 agente

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
`docs/plans/<plan>/breakdown/`, y el flujo funciona igual sin cuenta.

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

---

## Artefactos y configuración

```
docs/plans/<plan>/
├── spec.md          # requerimiento aprobado y validado
├── spec-check.md    # veredicto del validador externo
├── plan.md          # decisiones, matriz de archivos, olas, configuración
├── tasks/
│   ├── T-001.md     # estado en frontmatter + bitácora
│   └── T-002.md
└── reviews/         # prompts y veredictos de cada revisión
```

Cada archivo de tarea tiene un único escritor: el agente asignado a esa tarea. El campo
`estado` de su frontmatter es la fuente de verdad.

Toda la configuración vive en el frontmatter de `plan.md`, escrito una vez por `/breakdown`:

```yaml
tracker: archivos                               # archivos | linear
cmd_test: npm test
cmd_build: npm run build
cmd_lint: npm run lint
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

## Limitaciones conocidas

- **Despliegue fuera de alcance.** El flujo termina en código revisado y commiteado.
- **Validación del grafo manual.** `/breakdown` verifica ciclos y dependencias inexistentes
  con un checklist, no con una herramienta.
- **`/autopilot` sin validar de punta a punta** contra un repositorio real con revisor
  externo. Arranca con `/autopilot task T-001` y un agente antes de escalar.
