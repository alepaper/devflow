# Worktrees

Dos o más agentes en paralelo significa dos o más worktrees. Un worktree por tarea, no
por agente: la tarea es la unidad que se commitea, se revisa y se revierte.

## Por qué: sin aislamiento, el TDD no se puede hacer cumplir

Evitar que dos agentes se pisen los archivos sin commitear es lo obvio, y la matriz de
archivos ya lo cubre en buena medida. La razón de fondo es otra.

Los tres pasos del ciclo hacen una pregunta que un árbol compartido vuelve
incontestable:

| Paso | La pregunta | En árbol compartido |
|---|---|---|
| RED | ¿falló por la razón correcta? | Pudo fallar por el módulo a medio escribir de otro agente |
| GREEN | ¿pasó por mi código? | Pudo pasar por el de otro |
| Suite completa | ¿rompí algo? | Rojo por trabajo ajeno, indistinguible del propio |

El tercero decide. Antes de commitear, el agente corre la suite completa. Si está roja
por el estado intermedio de otro, le quedan dos salidas: esperar — y entonces ya
serializó, el paralelismo se perdió igual — o decidir que "esos fallos no son míos" y
commitear igual. Lo segundo convierte la compuerta en teatro, y no hay forma confiable de
separar la regresión propia del trabajo ajeno a medias.

Con un solo agente nada de esto aplica: no hay de qué aislarse y `cmd_setup` se pagaría
para nada. **Worktrees solo con dos o más agentes.**

## Precondición: T-000 cerrada

No se crea ningún worktree antes de que T-000 esté `done`. Esa tarea es la que garantiza
que `cmd_setup` funcione y que `.gitignore`, `.env.example`, los lockfiles y la
configuración estén en su lugar.

Un worktree creado sobre una base incompleta no puede correr la suite, y entonces estás
depurando el mismo `.env.example` faltante en tres copias a la vez en lugar de una.

T-000 también hace el primer commit si el repositorio no tiene ninguno: `git worktree
add` falla en un repo sin commits.

## Montaje

### Rama de integración, una vez por plan

```bash
git switch -c devflow/<plan>
```

Las tareas se integran aquí, no en la rama base. La base nunca ve un plan a medias, y la
rama de integración es el único lugar donde la suite completa debe estar verde.

### Un worktree por tarea de la ola

```bash
git worktree add ../<repo>-T-002 -b devflow/<plan>-T-002 devflow/<plan>
git worktree add ../<repo>-T-003 -b devflow/<plan>-T-003 devflow/<plan>
```

**El guion antes del id de tarea no es estético.** Git guarda las ramas como rutas de
archivo, así que no pueden coexistir `devflow/<plan>` y `devflow/<plan>/T-002`: la primera
sería un archivo y la segunda exigiría que fuera un directorio. Con barra, el segundo
`worktree add` falla con `cannot lock ref ... exists`.

El guion además deja el filtro de limpieza limpio: `devflow/<plan>-*` lista las ramas de
tarea sin incluir la de integración.

El último argumento es el punto de partida: la rama de integración **como está al
comenzar la ola**. Así cada tarea ve sus dependencias ya integradas, que es justo lo que
las olas garantizan.

### Preparar cada worktree

Un worktree nuevo trae solo lo versionado. No trae `node_modules`, `.venv`, `target/`,
`vendor/` ni nada ignorado — y tampoco `.env`. La suite no corre hasta prepararlo:

```bash
cd ../<repo>-T-002
<cmd_setup>                 # npm ci, uv sync, bundle install, lo que aplique
cp ../<repo>/.env .env      # y cualquier otro archivo ignorado que la suite necesite
```

`cmd_setup` vive en el frontmatter de `plan.md`. Si falla en un worktree, el defecto está
en T-000, no en el worktree: arréglalo ahí y vuelve a crearlo. Parchear el worktree a
mano esconde el problema y el siguiente lo repite.

El costo de `cmd_setup` se multiplica por el ancho de la ola, así que el gestor importa:
`pnpm` y `uv` mantienen un almacén compartido y enlazan duro, de modo que N worktrees
cuestan ~1 copia en disco y cada instalación después de la primera es casi instantánea.
Con `npm` o `pip`, son N copias completas. Detalles y detección en
`../../breakdown/references/package-managers.md`.

Las cachés (`~/.npm`, `~/.cache/uv`, el almacén de pnpm) son inmutables y se comparten
sin riesgo. Lo que nunca se comparte es `node_modules` ni `.venv`: ahí escribe el build, y
compartirlos reintroduce el problema que los worktrees resuelven.

## Integración

### Orden de dependencia, no de terminación

```bash
git switch devflow/<plan>
git merge --no-ff devflow/<plan>-T-002
<cmd_test>
```

`--no-ff` conserva el límite de la tarea, que es lo que mantiene cada una revertible por
separado.

**La suite completa debe quedar verde después de cada merge.** No al final de la ola:
después de cada uno. Si se rompe en el tercero de cuatro, quieres saber que fue el
tercero.

### Merge inmediato, no al final

Una tarea aprobada se integra en seguida. Juntar seis ramas al final es un problema peor
que hacer seis merges pequeños, y además retrasa el descubrimiento de conflictos
semánticos hasta cuando ya no recuerdas el contexto.

### Limpieza

**Un worktree se elimina en cuanto deja de necesitarse, no al final del plan.** No es
higiene: lo que ocupa espacio no es el checkout — son los `node_modules`, `.venv`,
`target/` o `vendor/` que `cmd_setup` instaló dentro. Cuatro worktrees de un proyecto
Node son cuatro copias completas del árbol de dependencias.

Hay tres momentos en que un worktree deja de necesitarse, y los tres obligan a limpiar:

| Momento | Qué hacer |
|---|---|
| La tarea se mergeó y fue aprobada | Eliminar worktree y rama |
| La tarea se abandona: `blocked` sin resolución, o el plan cambió | Eliminar el worktree. **Conservar la rama** hasta que el usuario decida |
| La sesión terminó a mitad del plan | Quedan huérfanos; se detectan y limpian al retomar |

El segundo es el que se olvida. La limpieza no puede colgar solo del camino feliz: una
tarea bloqueada deja su worktree ocupando lo mismo que uno activo, y a veces durante días.

#### Procedimiento

```bash
git worktree remove ../<repo>-T-002
git branch -d devflow/<plan>-T-002
```

`git worktree remove` se niega si hay archivos **no rastreados y no ignorados** en el
worktree. Eso es una protección, no un estorbo: significa que ahí hay contenido que se
creó y nunca se declaró ni commiteó.

**Nunca uses `--force` sin mirar primero qué destruiría:**

```bash
git -C ../<repo>-T-002 status --porcelain --untracked-files=normal
```

Si lo que aparece es basura de la corrida, `--force`. Si es trabajo real, es una tarea
que no declaró un archivo — regístralo y arregla el plan antes de borrar nada.

`git branch -d` falla si la rama no está integrada. También es una red: no uses `-D` sin
entender por qué falló.

#### Huérfanos de sesiones anteriores

Al retomar un plan, antes de crear worktrees nuevos:

```bash
git worktree list
```

Todo lo que aparezca aparte del repositorio principal y no corresponda a una tarea en
vuelo es huérfano. Para ver cuánto espacio retienen:

```bash
du -sh ../<repo>-*
```

Elimina cada uno con el procedimiento de arriba. Si el directorio ya no existe porque
alguien lo borró a mano, git conserva su metadata en `.git/worktrees/`:

```bash
git worktree prune
```

#### Al cerrar el plan

```bash
git switch <rama-base> && git merge --no-ff devflow/<plan>
git worktree prune
git worktree list          # debe quedar solo el repositorio principal
git branch --list 'devflow/<plan>-*'   # debe salir vacío
```

Las dos últimas líneas son la verificación. Un plan terminado que deja worktrees o ramas
de tarea no está terminado: está dejando gigabytes y ruido en `git branch`.

La rama de integración `devflow/<plan>` sí se puede conservar hasta que confirmes que
todo quedó bien en la base.

## Cuando algo sale mal

### Conflicto de merge

**Significa que el plan estaba mal.** Dos tareas compartían un archivo que la matriz dijo
que no compartían.

No lo resuelvas a mano. Registra qué archivos chocaron, para, y arregla el plan. Una
resolución improvisada repara el síntoma y deja el defecto de planeación intacto, así que
vuelve a pasar en la siguiente ola — y la siguiente vez puede ser en un archivo donde la
resolución no sea obvia.

Causas típicas, en orden de frecuencia:

| Causa | Arreglo en el plan |
|---|---|
| Archivo de bloqueo de dependencias (`package-lock.json`, `uv.lock`) | Los cambios de dependencias van a **una** tarea aguas arriba |
| Archivo generado y versionado (barriles, esquemas, tipos) | Lo regenera una sola tarea, o se deja de versionar |
| Numeración de migraciones | Las migraciones son siempre secuenciales, nunca en paralelo |
| Un archivo que la matriz no vio porque la tarea no lo declaró | La declaración de archivos estaba incompleta |

### Merge limpio pero suite roja

Peor que un conflicto, y **la matriz de archivos no puede atraparlo**. Las dos tareas no
tocaron ningún archivo común, pero cambiaron el mismo comportamiento: una suposición
compartida, un contrato que una lado alteró, un fixture del que la otra dependía.

Es un conflicto semántico. La exclusividad de archivos nunca prometió prevenirlo —
previene escrituras simultáneas, no acoplamiento lógico.

Es condición de parada: di cuáles dos tareas, qué test se cayó, y deja que el usuario
decida. El arreglo suele ser una tarea nueva, no un parche dentro de una de las dos.

### Una tarea devuelta a revisión tras haberse integrado

Si `cross-review` pide cambios después del merge, el arreglo es una tarea nueva sobre la
rama de integración, no un `revert` de la anterior. Revertir reabre todo lo que se mergeó
encima.

## Cuántos worktrees

El ancho de la ola, con tope de 4. **Con un solo agente, ninguno**: se trabaja directo
sobre la rama de integración.

Cada worktree cuesta un `cmd_setup`. Con `pnpm` o `uv` ese costo es pequeño y tres
agentes salen baratos; con `npm ci` o `pip` en un proyecto grande, el costo por agente
extra puede superar lo que ahorra el paralelismo. Si la ola más ancha es 2 y
`cmd_setup` tarda minutos, un solo agente probablemente rinde más.
