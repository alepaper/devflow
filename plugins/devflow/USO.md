# Cómo se usa

Guía práctica: qué escribes, qué pasa, y qué decides tú.

Las skills se activan solas cuando la conversación lo pide, pero escribir el comando es
más rápido y deja claro dónde estás en el flujo.

Instalado como plugin, los comandos llevan prefijo: `/devflow:spec`. Esta guía usa la
forma corta `/spec`, que funciona igual mientras nada más reclame ese nombre. Si tienes
varios plugins instalados, usa siempre el prefijo.

---

## Antes de empezar, una vez por proyecto

### Verifica el revisor

Esto se hace **antes** de la primera tarea, no después de cinco. Si usas codex:

```bash
printf 'Responde únicamente con este bloque, sin nada más:\n\nVERDICT: APPROVED\nBLOCKERS:\nNITS:\n' \
  | codex exec --skip-git-repo-check -
```

Debe salir `VERDICT: APPROVED`. Si no sale, arregla el comando ahora. Sin revisor
externo puedes usar un subagente de Claude, pero es más débil: mismo modelo, mismos
puntos ciegos.

### Árbol limpio

`/autopilot` hace un commit por tarea. Si tienes cambios sueltos ajenos al plan, se te
van a colar adentro y pierdes el punto de rollback limpio. Commitea o guarda en stash
antes de arrancar.

---

## El flujo completo

### 1. Levantar el requerimiento

```
/spec recuperación de contraseña
```

Claude arranca con una hipótesis y un número de confianza, y después pregunta **una cosa
a la vez**, cada pregunta con su suposición adjunta:

```
HIPÓTESIS: Quieres que la gente recupere su cuenta sin escribirle a soporte.
CONFIANZA: ~35% — falta: qué pasa hoy, qué canal usan, cuánto dura el token.

P: ¿El correo de recuperación sale de tu sistema o de un proveedor tipo SendGrid?
   SUPONGO: un proveedor, porque montar entregabilidad propia para esto rara vez vale
   la pena.
```

Respóndele corto. Va a seguir hasta poder predecir tus siguientes tres respuestas.

**Dos respuestas que no le sirven:** "lo que tú veas" es delegación, no decisión, y te va
a devolver dos opciones concretas. "Suena bien" ante el resumen final es ambiguo y te va
a preguntar qué ajustarías.

**Puedes llegar con todo escrito.** `/spec` acepta un párrafo o tres páginas, y una
descripción larga es mejor: menos preguntas y más confianza inicial. Si te llega completo,
lo primero que hace no es preguntar sino **devolverte lo que entendió** y pedirte que lo
corrijas:

```
Entendí esto:
- El problema es que los vendedores pierden pedidos de WhatsApp, no que falte un CRM
- La restricción dura es que no puede tocar el ERP actual
- Lo que NO está definido: cómo sabrías en 3 meses que funcionó

¿Qué leí mal?
```

Eso existe porque una descripción larga **se siente** completa. Un malentendido atrapado
ahí cuesta un mensaje; atrapado después del plan, cuesta el plan.

Después va directo a los huecos. Los briefs largos son consistentes: cubren bien *qué* se
construye y casi siempre callan *por qué ahora*, *cómo sabrías que funcionó* y *qué queda
fuera*. También te va a señalar contradicciones del propio documento — "dice dos semanas
y también integración con tres sistemas sin API; una tiene que ceder" — que valen más que
tres preguntas nuevas.

### 1b. Validar el spec antes de aprobarlo

Antes de pedirte el sí, corre tres capas de validación. No te va a preguntar "¿te parece
bien?" — eso siempre produce un sí hueco.

**Auditoría de falsabilidad.** Pasa cada criterio de éxito por una prueba mecánica:
*¿podrían dos personas estar en desacuerdo sobre si se cumplió?* "Rápido", "fácil de
usar" y "escalable" no sobreviven. También busca requerimientos que en realidad son
soluciones, términos sin definir, y dependencias que asume que existen.

**Escenarios.** En vez de pedirte aprobación, te da tres a cinco situaciones concretas:

```
Antes de aprobar, tres situaciones. Dime qué debería pasar:

1. Alguien sin autorización abre directo la URL de administración de permisos.
2. Un sistema no responde cuando la app le pregunta por su estado.
3. Se revoca el acceso de alguien que ya salió, pero ese sistema no tiene
   revocación programática.
```

Si el spec ya lo responde, esa parte está sólida. Si dudas o dices "no lo había
pensado", encontraste un hueco — y esa es la parte más valiosa de todo el paso. Las
respuestas quedan escritas en el documento.

**Validación por otro agente.**

```
/spec-check
```

Manda el spec a codex (o a un subagente con contexto limpio) **sin la conversación**. Ese
agente solo ve el documento, que es exactamente lo que verá quien lo construya. Devuelve
un veredicto: `LISTO`, `HUECOS` o `BLOQUEADO`.

`HUECOS` es el resultado normal y útil. Cada hueco vuelve como pregunta para ti, nunca
como algo que Claude rellene solo — rellenar un hueco con una inferencia es exactamente
lo que la validación estaba probando.

Puedes correrlo suelto sobre cualquier spec, incluso uno que no escribiste:

```
/spec-check docs/plans/portal-ds/spec.md
```

Termina en `docs/plans/<slug>/spec.md` con `estado: aprobado`, y **para**. No planea en el
mismo turno. El frontmatter deja registro de qué capas corrieron:

```yaml
validado_con: [auditoria, escenarios, spec-check]
spec_check: LISTO
```

### 2. Partir en tareas

```
/breakdown
```

Si tienes varios specs escritos, primero te los lista con su estado y validación para que
elijas uno, varios o todos. Los que estén en `borrador` los marca como no planeables, y
si alguno ya tiene plan con tareas abiertas te pregunta antes de tocarlo.

Si eliges varios, la matriz de archivos abarca todos: dos planes distintos pueden chocar
en un archivo igual que dos tareas del mismo plan, y las dependencias entre planes se
escriben calificadas (`portal-ds/T-003`).

Si el cambio revierte algo que ya existe — un nombre, un default, una regla, una
dependencia — primero inventaría **qué afirma hoy eso que va a cambiar**: documentación,
plantillas, ejemplos, mensajes de error, tests que codifican la regla vieja. Cada
superficie recibe una tarea dueña.

Ese paso existe porque la matriz de archivos responde "¿estas tareas chocan?", no "¿está
completa la lista?". Sin él, el texto obsoleto aparece en revisión.

Si el cambio revierte algo que ya existe — un nombre, un default, una regla, una
dependencia — primero inventaría **qué afirma hoy eso que va a cambiar**: documentación,
plantillas, ejemplos, mensajes de error, tests que codifican la regla vieja. Cada
superficie recibe una tarea dueña.

Ese paso existe porque la matriz responde "¿estas tareas chocan?", no "¿está completa la
lista?". Sin él, el texto obsoleto aparece en revisión, que es el lugar caro.

Lee el spec, reconoce el código, detecta tus comandos reales de test y build, y arma la
**matriz archivo → tareas**. Ahí es donde aparece lo interesante:

```
| Archivo                     | Tareas              |
| src/lib/permisos/cliente.ts | T-001, T-005, T-006  ← COLISIÓN
```

Tres tareas necesitan el mismo archivo. Como dos tareas nunca pueden compartir archivo,
eso se resuelve de una de tres formas: partir el archivo, extraer una tarea aguas arriba
que haga todas sus ediciones, o encadenarlas. Claude propone; tú decides.

Al final te muestra el mapa de olas y **cuántos agentes sirven de verdad**:

```
Ola 1: T-000                 → 1 agente   (base del proyecto, siempre sola)
Ola 2: T-001, T-002, T-003   → 3 agentes
Ola 3: T-004, T-005, T-006   → 3 agentes

Agentes recomendados: 3
```

Si te dice "1 agente", créele. Un plan encadenado con tres agentes son dos agentes
mirando.

Revisa la matriz antes de aprobar. Es la evidencia de que el plan es seguro en paralelo,
y es lo único que un humano puede verificar de un vistazo.

### 3. Tablero en Linear, si quieres

```
/tracker
```

Opcional y reversible. Si no lo corres, las tareas viven en archivos y funciona igual.
Si ya tienes progreso y conectas después, migra preservando estado: una tarea en `done`
se crea en Done, no en Todo.

Los archivos de tarea siguen siendo la fuente de verdad. Linear es el espejo para gente.

### 4. Ejecutar

```
/autopilot
```

Te pregunta con cuántos agentes arrancar, reparte tareas **por nombre** (nadie elige la
suya), y por cada una: tests que fallan primero → código mínimo → refactor → suite
completa → build → commit solo de los archivos declarados → revisión por otro agente →
merge → aprobada.

Te notifica al terminar cada tarea y al terminar todo.

**La primera tarea siempre es T-000**, la base del proyecto, y corre sola. Verifica que
exista el cimiento: git con al menos un commit, `.gitignore` que cubra `node_modules` y
`.env`, `.env.example` completo, lockfiles commiteados, configuración y un test trivial
que pase. En un repo ya armado cierra rápido; es verificación, no burocracia.

Cierra cuando un clon limpio corre `cmd_setup`, la suite y el build sin errores. Ese
chequeo es el que garantiza que después todos los worktrees funcionen.

**Con dos o más agentes, cada tarea corre en su propio worktree.** Crea la rama de
integración `devflow/<plan>` y un worktree por tarea de la ola:

```
../mi-app-T-002    rama devflow/mi-plan/T-002
../mi-app-T-003    rama devflow/mi-plan/T-003
```

Con un solo agente no hay worktrees. Con dos o más son obligatorios, y no por los
archivos — eso ya lo cubre la matriz. Es por el TDD: antes de commitear, el agente corre
la suite completa; si está roja por el trabajo a medias de otro, no puede distinguirla de
una regresión propia, y la compuerta deja de significar algo.

Cada tarea aprobada se integra de inmediato en `devflow/<plan>`, en orden de dependencia,
con la suite verde después de cada merge. Al terminar el plan esa rama va una sola vez a
tu rama base.

**El worktree se elimina apenas la tarea se mergea**, o si queda bloqueada. Lo que ocupa
espacio no es el checkout: son los `node_modules` o `.venv` que `cmd_setup` instaló
adentro, y cuatro tareas en paralelo son cuatro copias completas. Al cerrar el plan,
`git worktree list` debe mostrar solo tu repositorio.

Si una sesión se corta a mitad, quedan worktrees huérfanos. `/progress` te los reporta
con cuánto disco retienen, y `/autopilot` los limpia antes de crear la siguiente ola.

Necesitas `cmd_setup` configurado en `plan.md`: un worktree nuevo no trae `node_modules`
ni `.env`, y sin eso la suite no corre ahí. Lo decide el lockfile del proyecto —
`pnpm-lock.yaml` → `pnpm install --frozen-lockfile`, `package-lock.json` → `npm ci`,
`uv.lock` → `uv sync --frozen`.

Si estás arrancando un proyecto nuevo, `pnpm` y `uv` valen la pena: comparten un almacén
y enlazan duro, así que cuatro worktrees ocupan ~1 copia de dependencias en vez de
cuatro. Con `npm` o `pip` cada agente extra cuesta un árbol completo en disco.

Con un solo agente no hay worktrees: se trabaja directo sobre la rama de integración.

---

## Usarlo por pedazos

El loop no es todo o nada.

```
/autopilot dev            implementa con TDD, deja todo en in_review, para
/autopilot review         solo revisa lo que está esperando
/autopilot test           solo corre la suite y arregla rojos
/autopilot task T-003     solo esa tarea, loop completo
```

Sirve cuando quieres implementar hoy y revisar mañana con la cabeza fresca, o cuando
codex está caído y no quieres frenar el desarrollo.

Para revisar una tarea suelta sin pasar por autopilot:

```
/cross-review T-003
```

---

## Proyectos de versiones anteriores

Si creaste planes con una versión previa, puede que la carpeta se llame `breakdown/` en
vez de `tasks/`, o que el documento del plan sea `tasks.md` o `breakdown.md`. Fueron dos
renombres de comando que arrastraron rutas por error.

No tienes que hacer nada: las skills leen ambos nombres, y la primera que escriba en el
plan — `/breakdown` o `/autopilot` — lo renombra al layout canónico, corrige las
referencias internas y lo deja en un commit propio. Te lo dice en una línea.

`/progress` solo te avisa, porque no escribe nada.

Dos casos en que para y pregunta: si existen `tasks/` y `breakdown/` a la vez (migración a
medias), y si hay una ola en vuelo — ahí hay agentes con rutas ya resueltas y worktrees
creados, así que la migración espera a que cierre.

---

## Retomar después de días

```
/progress
```

Solo lectura. Te dice qué está hecho, qué está en vuelo y con qué agente, qué está
esperando y por quién, y **cuál es la próxima decisión que te toca**.

También señala cosas raras sin arreglarlas: una tarea `in_progress` hace tres sesiones
sin entradas nuevas en bitácora, un `done` sin veredicto de revisión, dos tareas en vuelo
con archivos solapados. Eso último es un defecto del plan y hay que arreglarlo en el
plan, no improvisando.

Para seguir donde ibas:

```
/autopilot
```

Recalcula qué está listo y sigue. El estado vive en los archivos de tarea, así que
retomar entre sesiones no cuesta nada.

---

## Cuando se bloquea

Se detiene y te pregunta en estos casos, y en todos la respuesta correcta es contestarle,
no insistirle:

| Situación | Qué hacer |
|---|---|
| Un test no pasa sin arreglo obvio | Mira el error con él. Puede ser que el criterio esté mal escrito. |
| Tercera ronda de CHANGES_REQUESTED | La tarea está mal especificada, no mal implementada. Vuelve al spec o pártela. |
| Toca auth, pagos, migraciones destructivas o borrado de datos | Autoriza explícitamente o saca eso del alcance. |
| Un agente necesita un archivo que su tarea no declaró | La matriz falló. Arregla el plan antes de seguir. |
| Un worktree no puede correr la suite | Defecto de T-000: `cmd_setup` está incompleto. Arréglalo ahí, no parcheando el worktree. |
| Conflicto de merge al integrar | El plan estaba mal: dos tareas compartían archivo. Se arregla en el plan, no resolviendo el conflicto a mano. |
| Merge limpio pero la suite roja | Conflicto semántico: dos tareas que no comparten archivo cambiaron el mismo comportamiento. La matriz no previene esto. Decide tú el arreglo. |
| El spec no cubre una decisión | Contéstala. Adivinar es cómo se construye lo equivocado con confianza. |

---

## Errores comunes

**Saltarse `/spec` porque "el pedido ya está claro".** Si no puedes escribir el resultado
deseado en una frase ahora mismo, no lo está. Es la hora más barata del proyecto.

**Montar más agentes que el ancho de la ola.** Los sobrantes se quedan esperando y
aumentan el riesgo de conflicto. El número que te da `/breakdown` es el útil.

**Aprobar el plan sin mirar la matriz ni el inventario.** La matriz es lo que garantiza
que el paralelismo no choque; el inventario es lo que garantiza que la lista de archivos
esté completa. Las dos son rápidas de revisar y responden preguntas distintas.

**Pedirle a Claude que revise su propio código.** No lo va a hacer, y si insistes vas a
obtener una revisión sin valor: comparte los puntos ciegos que produjeron el código.

**Correr `/autopilot` con el árbol sucio.** Los cambios ajenos se cuelan en los commits
por tarea y pierdes el rollback limpio.

---

## Prompt de arranque para un proyecto nuevo

Pégalo en Claude Code dentro del repo:

> Tengo instalada la librería de skills **devflow**: `/spec`, `/breakdown`, `/autopilot`,
> `/cross-review`, `/progress`, `/tracker`, más la skill `tdd` que se activa sola.
>
> Quiero construir: **<describe en una o dos frases lo que quieres>**
>
> Arranca con `/spec`. Entrevístame una pregunta a la vez, con tu suposición adjunta,
> hasta que puedas predecir mis siguientes tres respuestas. No planees ni escribas código
> hasta que yo apruebe el spec explícitamente.
>
> Contexto del proyecto que te ahorro preguntar:
> - Stack: **<lenguaje, framework, base de datos>**
> - Cómo corro los tests: **<comando>**
> - Cómo compilo: **<comando>**
> - Reviso con: **<codex / gemini / subagente de Claude>**

Las últimas cuatro líneas le ahorran el reconocimiento y quedan guardadas en el
frontmatter de `plan.md` para que `/autopilot` las use después.

---

## Lo que pasa solo

`tdd` no tiene comando y no aparece en el menú de `/`. Se activa sola cada vez que se
implementa algo, se arregla un bug o se rompe un test, y es lo que hace cumplir que los
tests se escriban antes del código.

Las notificaciones de escritorio también salen solas al terminar cada tarea y al terminar
el plan. Si quieres que además lleguen a Slack o Discord, pon la URL del webhook en el
frontmatter de `plan.md`.
