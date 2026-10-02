# Gestores de paquetes y `cmd_setup`

`cmd_setup` prepara un worktree recién creado. Se corre una vez por worktree, así que su
costo se multiplica por el ancho de la ola. Elegir bien es lo que hace asequible correr
tres agentes.

## La regla que manda: decide el lockfile, no la máquina

Cambiar de gestor en un proyecto existente **cambia la resolución de dependencias**. No
es una sustitución transparente: `pnpm` usa un `node_modules` no plano con enlaces
simbólicos, y los paquetes que dependen del *hoisting* de npm se rompen.

Así que la preferencia (`pnpm`, `uv`) aplica **solo** cuando el proyecto todavía no tiene
lockfile — es decir, cuando T-000 está creando la base de un proyecto nuevo. Si ya hay
lockfile, manda el lockfile.

### Node

| Lockfile presente | `cmd_setup` |
|---|---|
| `pnpm-lock.yaml` | `pnpm install --frozen-lockfile` |
| `package-lock.json` | `npm ci --prefer-offline` |
| `yarn.lock` | `yarn install --immutable` |
| ninguno (proyecto nuevo) | `pnpm` si está instalado, si no `npm` |

### Python

| Marcador presente | `cmd_setup` |
|---|---|
| `uv.lock` | `uv sync --frozen` |
| `poetry.lock` | `poetry install --sync` |
| `requirements.txt` | `uv pip install -r requirements.txt` si hay `uv`, si no `pip install -r requirements.txt` |
| ninguno (proyecto nuevo) | `uv` si está instalado, si no `venv` + `pip` |

`uv pip` sí es sustituto directo de `pip` sobre `requirements.txt`: lee el mismo formato y
resuelve igual. Esa es la excepción a la regla de arriba, y vale usarla aunque el proyecto
venga de pip.

## Detección

```bash
command -v pnpm >/dev/null 2>&1 && echo pnpm || echo npm
command -v uv   >/dev/null 2>&1 && echo uv   || echo pip
```

Si **ninguno** de los dos existe para una pila que el proyecto usa, no hay alternativa que
inventar: el entorno está incompleto. Para y dile al usuario qué instalar.

> No encuentro `pnpm` ni `npm`, y el proyecto tiene `package.json`.
> Instala Node (que trae npm) o pnpm antes de seguir. Sin eso no puedo preparar
> ningún worktree ni correr la suite.

Lo mismo con Python: sin `uv` ni `pip`, la instalación de Python está rota y hay que
arreglarla antes.

## Por qué `pnpm` y `uv` importan aquí

Los dos usan un **almacén compartido direccionado por contenido** y enlazan duro (hard
links) hacia `node_modules` o `.venv`. Las consecuencias para worktrees son grandes:

| | `npm` / `pip` | `pnpm` / `uv` |
|---|---|---|
| Disco con N worktrees | N copias completas | ~1 copia, enlazada N veces |
| Segunda instalación en adelante | descarga/copia otra vez | enlaces, casi instantáneo |

Con `npm`, cuatro worktrees de un proyecto mediano son cuatro árboles de dependencias
completos en disco. Con `pnpm`, es uno. Esa diferencia es la que decide si tres agentes
en paralelo son viables o un lujo.

No es solo "caché más rápida": es que el costo por worktree extra tiende a cero.

## Caché

| Gestor | Dónde | Qué hacer |
|---|---|---|
| `pnpm` | almacén global, `pnpm store path` | nada, es automático |
| `npm` | `~/.npm` | `--prefer-offline` para usarla antes que la red |
| `uv` | `~/.cache/uv` | nada, es automático |
| `pip` | `~/.cache/pip` | activa por defecto; **no** pases `--no-cache-dir` |

La caché es inmutable y se puede compartir entre worktrees sin riesgo. Lo que **no** se
comparte es `node_modules` ni `.venv`: ahí escribe el build, y compartirlos reintroduce
exactamente el problema que los worktrees resuelven.

## Siempre con lockfile congelado

`--frozen-lockfile`, `--immutable`, `npm ci`, `uv sync --frozen`: todos fallan si el
lockfile no concuerda con el manifiesto, en vez de actualizarlo.

Eso importa más de lo que parece aquí. Un `cmd_setup` que modifica el lockfile lo hace en
cada worktree a la vez, y produce un conflicto de merge garantizado en un archivo que
ninguna tarea declaró.

## Convertir de gestor

`pnpm import` genera `pnpm-lock.yaml` desde `package-lock.json`, y `uv` puede partir de
`requirements.txt`. Pero es un cambio de resolución de dependencias con riesgo real de
romper el build.

**Nunca lo hagas en silencio dentro de `cmd_setup`.** Si vale la pena, es una tarea propia
con sus criterios de aceptación — y la suite completa verde es el criterio.
