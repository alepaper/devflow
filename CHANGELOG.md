# Changelog

Formato según [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

> El contenido de 1.1.0 y 1.0.0 está reconstruido a partir de lo que hay en la librería.
> Si tus etiquetas del repositorio dividen el trabajo de otra forma, ajusta esas dos
> secciones. La de 1.2.0 es exacta.

---

## [1.2.0] — sin publicar

Ejecución en paralelo con aislamiento real, base del proyecto garantizada, y corrección
de un defecto que afectaba a todos los planes.

### Agregado

- **T-000, tarea base de todo plan.** Verifica el cimiento versionado antes de que
  cualquier otra tarea arranque: repositorio git con al menos un commit, `.gitignore` que
  cubra dependencias y secretos, `.env.example` completo, manifiestos con sus lockfiles,
  configuración de linter y runner, y un test trivial que pase. Cierra con un criterio que
  subsume a los demás: un clon limpio corre `cmd_setup`, la suite y el build sin errores.
  Lo no versionado (`node_modules`, `.venv`) no puede ser producto de una tarea — está
  ignorado, así que no queda nada commiteado. El trabajo de T-000 es hacer que
  `cmd_setup` funcione.

- **Worktrees para ejecución en paralelo**, uno por tarea, solo con dos o más agentes.
  Con un agente se trabaja directo sobre la rama de integración.

- **Rama de integración `devflow/<plan>` y protocolo de merge.** Cada tarea aprobada se
  integra de inmediato, en orden de dependencia, con la suite completa verde después de
  cada merge. Al cerrar el plan, esa rama va una sola vez a la rama base.

- **Limpieza de worktrees en tres momentos**: al mergear, al quedar la tarea bloqueada o
  abandonada, y al detectar huérfanos de sesiones interrumpidas. Incluye salvaguarda
  contra `--force` — archivos sin rastrear suelen significar que la tarea tocó algo que no
  declaró. Al cerrar el plan la limpieza se verifica, no se asume.

- **Detección de gestor de paquetes** con preferencia por `pnpm` y `uv`, caída a
  `npm`/`pip`, y parada con instrucción al usuario si no hay ninguno para una pila en uso.
  La preferencia no es estética: ambos mantienen un almacén compartido y enlazan duro, así
  que N worktrees cuestan ~1 copia en disco en vez de N. **El gestor lo decide el lockfile
  del proyecto, no la preferencia** — cambiarlo altera la resolución de dependencias.
  Siempre en forma congelada, porque un `cmd_setup` que actualiza el lockfile lo hace en
  todos los worktrees a la vez.

- **Compatibilidad con layouts de planes anteriores.** Las cinco skills que abren un plan
  resuelven `tasks/` con caída a `breakdown/`, y `plan.md` con caída a `tasks.md` y
  `breakdown.md`. Las que escriben migran al layout canónico con `git mv` en un commit
  aparte y corrigen las referencias internas; `/progress` solo lo reporta, porque es de
  solo lectura.

- `cmd_setup` y `worktree_files` en el frontmatter de `plan.md`.
- `/progress` reporta worktrees huérfanos con cuánto disco retienen.
- Referencias nuevas: `worktrees.md`, `package-managers.md`, `plan-layout.md`.

### Cambiado

- **La skill `tdd` se invoca por nombre** en el brief de cada agente. Antes ninguna skill
  la nombraba y, al ser `user-invocable: false`, una de las tres invariantes dependía de
  que el subagente decidiera auto-cargarla teniendo un resumen de cuatro líneas delante.

- **Justificación de los worktrees corregida.** No es que el rojo ajeno sea ruido: es que
  sin aislamiento **la compuerta de suite verde no se puede hacer cumplir**. Cuando un
  agente corre la suite antes de commitear y está roja por el trabajo a medias de otro, le
  queda esperar — serializando, perdiendo el paralelismo igual — o commitear decidiendo
  que no es suyo, que convierte la compuerta en teatro.

- Cuarta invariante del autopilot: con más de un agente, cada tarea en su propio worktree.
- La ola 1 es siempre T-000 sola. Los mapas de olas de la documentación lo reflejan.
- `/breakdown` detecta `cmd_setup` durante el reconocimiento.

### Corregido

- **11 rutas de artefactos corrompidas por los renombres de comandos.**
  `docs/plans/<slug>/tasks/` había quedado como `.../breakdown/`, y `plan.md` como
  `breakdown.md`. Los agentes habrían buscado los archivos de tarea en un directorio
  inexistente. Venía del renombre `/plan` → `/tasks` y sobrevivió dos barridos de
  verificación porque los `grep` excluían `docs/plans`.

- Numeración rota en el brief del agente y en los pasos de setup del autopilot.
- Limitación conocida obsoleta: `/autopilot` ya se corrió de punta a punta.

### Limitaciones conocidas nuevas

- **Conflictos semánticos.** Dos tareas que no comparten archivo pueden romper el mismo
  comportamiento. La matriz de archivos no puede preverlo; aparece como merge limpio con
  suite roja, y es condición de parada.

---

## [1.1.0]

Capa de validación: garantizar que el requerimiento esté bien entendido antes de planear,
y que un cambio de comportamiento no deje texto obsoleto atrás.

### Agregado

- **Validación del spec en tres capas** antes de pedir aprobación. Auditoría de
  falsabilidad (*¿podrían dos personas estar en desacuerdo sobre si se cumplió?*),
  escenarios concretos en vez de "¿te parece bien?" — que siempre produce un sí hueco —, y
  validación por un agente distinto. Los huecos vuelven como pregunta para el usuario,
  nunca como algo que Claude rellene.

- **`/spec-check`**, octava skill. Envía el spec a otro agente **sin la conversación**,
  porque ese agente debe ver solo lo que verá quien construya. Veredicto estructurado:
  `LISTO`, `HUECOS` o `BLOQUEADO`. Se puede correr suelta sobre specs ajenos.

- **Inventario de afirmaciones** en `/breakdown`, antes de repartir archivos. La matriz
  responde "¿estas tareas chocan?", no "¿está completa la lista?". Inventaría qué afirma
  hoy el comportamiento que va a cambiar — documentación, plantillas, ejemplos, mensajes
  de error, tests que codifican la regla vieja — y cada superficie recibe tarea dueña.
  Busca de tres formas, porque cada una atrapa lo que las otras no: el nombre viejo, el
  concepto en prosa, y la afirmación inversa.

- **Selección entre varios specs** en `/breakdown`, con su estado y validación. Si se
  eligen varios, la matriz de archivos abarca todos: dos planes en paralelo pueden chocar
  igual que dos tareas del mismo plan.

- `/cross-review` busca afirmaciones obsoletas y las reporta como **defecto de
  planeación**, no solo como cambio pedido.

- Secciones nuevas en la plantilla de spec: Términos, Escenarios validados, Dependencias
  externas.

### Cambiado

- `/spec` acepta descripciones completas: con un brief largo, primero devuelve lo que
  entendió y pide corrección. Un brief largo *se siente* completo, y ahí es donde se
  construye sobre un malentendido.
- `/breakdown` avisa si el spec llega con `spec_check: HUECOS`.

---

## [1.0.0]

Primera versión funcional. Librería propia derivada de una de 25 skills y 9 comandos,
reducida a lo que el flujo necesita.

### Agregado

- **Siete skills**: `spec`, `breakdown`, `autopilot`, `cross-review`, `progress`,
  `tracker`, `tdd`.

- **Regla de exclusividad de archivos.** Dos tareas nunca pueden necesitar el mismo
  archivo; si lo necesitan, eso es una dependencia. `/breakdown` construye una matriz
  archivo → tareas y resuelve cada colisión partiendo el archivo, extrayendo una tarea
  aguas arriba, o encadenando.

- **Tres invariantes del autopilot**: tests antes del código, nadie aprueba su propio
  trabajo, nadie elige su tarea — el orquestador reparte, porque el auto-servicio permite
  que dos agentes lean el tablero en el mismo instante y tomen la misma.

- **Revisión cruzada con CLI externo** (`codex`, `gemini`) o subagente de contexto limpio,
  con veredicto estructurado y tope de tres rondas antes de escalar.

- **Modos parciales** de `/autopilot`: `dev`, `test`, `review`, `task T-00N`, `all`.

- **Linear opcional** como espejo del tablero, conectable después y reversible, con
  migración que preserva estado.

- Empaquetado como marketplace de Claude Code (`marketplace.json` + `plugins/devflow/`).

### Eliminado

- **El motor de estado en Python.** La primera versión traía un CLI con lock de archivo
  para reclamo atómico de tareas. La regla de exclusividad de archivos más el reparto por
  el orquestador lo hacen innecesario: sin auto-servicio no hay carrera que serializar. Se
  fueron también `state.json` y `log.md`, que eran archivos compartidos escritos por varios
  agentes — justo lo que la regla prohíbe. Cada archivo de tarea tiene ahora un único
  escritor.

- La carpeta `commands/`, redundante desde que los comandos personalizados se fusionaron
  con las skills.

### Decisiones de nombres

`/breakdown`, `/cross-review` y `/progress` en vez de `/plan`, `/review` y `/status`, que
están tomados por Claude Code. `/review` era el peor caso: es alias del `/code-review`
bundled, así que una skill propia llamada `review` nunca se habría ejecutado con ese
nombre, en silencio.
