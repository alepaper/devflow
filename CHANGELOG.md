# Changelog

Formato según [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).

> El contenido de 1.1.0 y 1.0.0 está reconstruido a partir de lo que hay en la librería.
> Si tus etiquetas del repositorio dividen el trabajo de otra forma, ajusta esas dos
> secciones.

---

## [1.3.0]

Cuatro huecos encontrados auditando la librería contra sí misma.

### Corregido

- **La revisión ya no filtra el diff por los archivos declarados.** Usaba
  `git diff ... -- <archivos de la tarea>`, de modo que el alcance de la auditoría lo
  definía justamente lo que podía estar violado: un agente que editara un archivo no
  declarado producía una revisión incapaz de verlo. Ahora recibe el commit completo, y la
  lista de archivos declarados entra **como dato a evaluar**, no como filtro. Un archivo
  fuera de la lista es bloqueante, porque significa que la matriz del plan tenía un hueco.

- **El RED deja evidencia.** Ocho lugares exigían que el test fallara primero y ninguno
  pedía prueba de que hubiera ocurrido. El revisor ve un commit donde test e
  implementación llegan juntos, así que el orden no vivía en ninguna parte. Ahora el
  agente pega la línea del fallo en la bitácora antes de implementar, y la revisión
  bloquea si falta o si el motivo del fallo no es coherente con que el código no
  existiera.

- **`cmd_lint` se usa.** Estaba declarado en la plantilla y ninguna skill lo consumía, así
  que el linting no corría nunca. Ahora va junto a tests y build en la verificación, con
  una regla para lo preexistente: si el lint falla en archivos que la tarea no tocó, se
  reporta y no se arregla — sería trabajo no declarado, y el revisor lo marcaría.

### Agregado

- **`documentar_codigo` en `plan.md`: `si` | `no`.** `/breakdown` detecta la convención del
  código existente y solo pregunta si no hay una clara. La respuesta se escribe en el
  Contexto de cada tarea, y `/cross-review` bloquea por un docstring faltante solo cuando
  es `si`.

  Binario a propósito: un desarrollador documenta lo que escribe o no lo documenta.
  Partirlo por "superficie pública" es convención de autor de bibliotecas y no significa
  nada en código de aplicación, que es la mayoría de los planes.

  El valor por defecto sigue siendo `no`, pero ahora como posición explícita y no como
  omisión: los tests describen el comportamiento y no pueden desviarse de él, los
  comentarios sí. Hasta aquí, la revisión trataba un docstring faltante como NIT sin que
  nadie hubiera decidido que ese era el criterio.

---

## [1.2.3]

### Corregido

- **Instalación rota: `"agents": "./agents"` en `plugin.json`.** El validador de Claude
  Code rechaza ese campo con `Validation errors: agents: Invalid input`, aunque la
  documentación lo declare como `string|array`. El plugin no se podía instalar en 1.2.2.

  Se quitó el campo. `agents/` en la raíz del plugin se autodescubre, igual que `skills/`
  y `commands/`, así que declararlo nunca fue necesario. El manifiesto quedó reducido a
  los campos que el validador acepta con certeza: `name`, `version`, `description`,
  `author`, `license`, `keywords`.

---

## [1.2.2]

### Agregado

- **Recomendación de cambiar a un modelo más ligero al terminar `/breakdown`.** Al aprobar
  el plan, las decisiones caras ya se tomaron; lo que queda en la sesión es coordinación, y
  el orquestador corre durante todo el plan, así que el ahorro se acumula por tarea. Uno
  más ligero, no el más barato que haya: el orquestador todavía juzga si un conflicto de
  merge es defecto de planeación o si una tarea que rebota está mal especificada. Se dice
  una vez, y se omite si `modelo_implementacion` es `inherit`.

### Cambiado

- **El mensaje de recomendación de modelo ahora pide, no informa.** Decía "los agentes de
  implementación corren con sonnet", que es un dato sobre los subagentes y no le pedía nada
  al usuario; la recomendación es sobre el modelo de la sesión. También se retiró la
  metáfora de escalera: "vuelve a subirlo" pasó a "cámbialo de vuelta por uno más capaz".

- **Sección "Ejemplo de uso" del README reducida de 161 a 110 líneas.** Los títulos llevan
  el comando, las comprobaciones previas quedaron como dos comandos en un bloque, y se
  retiraron los ejemplos de salida que solo ilustraban tono. Se conservaron los dos que
  enseñan a leer algo: la fila de colisión de la matriz y el mapa de olas.

- `/autopilot task T-001` → `task T-000` en la recomendación de primera corrida, que
  estaba desactualizada desde que T-000 se volvió obligatoria.

---

## [1.2.1]

Corrección de un esquema de nombres que rompía toda ola paralela, encontrada ejecutando
el flujo completo sobre un proyecto real.

### Corregido

- **Nombres de rama de tarea: `devflow/<plan>/T-00N` → `devflow/<plan>-T-00N`.**
  Git guarda las ramas como rutas de archivo, así que `devflow/<plan>` y
  `devflow/<plan>/T-002` no pueden coexistir: la primera sería un archivo y la segunda
  exigiría que fuera un directorio. El segundo `git worktree add` de cada ola fallaba con
  `cannot lock ref ... exists`. No fallaba a veces: fallaba siempre que hubiera dos o más
  agentes.

  El guion además deja correcto el filtro de limpieza — `devflow/<plan>-*` lista las ramas
  de tarea sin incluir la de integración, que con barra era ambiguo.

### Cambiado

- Título del README a **devflow para Claude Code**: el alcance va en el título en vez de
  en un párrafo al principio.
- Limitaciones conocidas reducidas a las dos reales. Los conflictos semánticos salieron
  de ahí: están manejados como condición de parada del protocolo de merge, y un caso
  manejado no es una limitación.
- Diagrama del pipeline realineado — las etiquetas habían quedado bajo el comando
  equivocado desde el renombre a `/breakdown`.

---

## [1.2.0]

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

- **Dos subagentes en `agents/`**: `devflow-implementer` (modelo configurable,
  `skills: [tdd]`, herramientas de edición, `maxTurns` acotado) y `devflow-reviewer`
  (solo lectura, **sin `tdd`**, prohibido editar código). La inyección de skills es
  acotada a propósito: una skill cargada donde no se usa es contexto que se paga en cada
  turno para nada.

- **Contrato de reporte terso.** Cada subagente devuelve un bloque fijo de seis líneas —
  tarea, estado, tests, commit, archivos, bloqueante — y nada más. Su mensaje final se
  queda en el contexto del orquestador el resto del plan: un reporte en prosa son ~2000
  tokens contra ~50, y con quince tareas eso degrada las decisiones además del costo. El
  detalle vive en la bitácora de la tarea.

- **Exploración movida a la planeación.** La sección `Contexto` de cada tarea trae rutas
  exactas, firmas reales copiadas del código y un archivo citado como patrón. Con N
  agentes, cualquier cosa que un implementador tenga que ir a buscar se busca N veces, en
  los modelos más numerosos y baratos. Regla que lo sostiene: si un implementador necesita
  explorar para entender qué hacer, la tarea estaba incompleta.

- **Elección de modelo para los agentes de implementación**, en `/spec`, una vez por
  proyecto. Pregunta y acepta: no inspecciona el entorno ni busca claves de API. El modelo
  de las fases de planeación es el de la sesión y lo fija el usuario con `/model`.

- `cmd_setup` y `worktree_files` en el frontmatter de `plan.md`.
- `/progress` reporta worktrees huérfanos con cuánto disco retienen.
- Referencias nuevas: `worktrees.md`, `package-managers.md`, `plan-layout.md`.

### Cambiado

- **`tdd` entra por configuración, no por decisión del agente.** Antes ninguna skill la
  nombraba y, al ser `user-invocable: false`, una de las tres invariantes dependía de que
  el subagente decidiera auto-cargarla teniendo un resumen de cuatro líneas delante. Ahora
  `devflow-implementer` la declara en `skills:`, así que entra de forma determinista.

- **El orquestador lee solo el frontmatter** de los archivos de tarea al recalcular qué
  está listo. Leer veinte archivos completos por ronda, cuando las primeras líneas
  responden la pregunta, es contexto que se paga en cada iteración.

- **Skills recortadas de 2189 a 2021 líneas.** El detalle de T-000, el inventario de
  afirmaciones, las capas de validación del spec y el protocolo de worktrees pasaron a
  referencias, que solo se cargan cuando hacen falta.

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
