# Instalar devflow

Tres vías. La primera es la correcta para uso normal.

---

## 1. Como plugin, vía marketplace local  ← recomendada

Este repositorio **es** un marketplace: tiene `.claude-plugin/marketplace.json` en la raíz
y el plugin en `plugins/devflow/`.

```bash
# parado en la carpeta PADRE de devflow/
claude plugin validate ./devflow
claude plugin marketplace add ./devflow
claude plugin install devflow@alepaper
```

### La ruta tiene que empezar por `./`, `../`, `/` o `~`

Es el error número uno. Claude Code acepta la fuente solo en cuatro formas:

| Forma | Ejemplo |
|---|---|
| `owner/repo` de GitHub | `alepaper/devflow` |
| URL http/https | `https://github.com/alepaper/devflow.git` |
| URL SSH | `git@github.com:alepaper/devflow.git` |
| Ruta local **que empiece por `./`, `../`, `/` o `~`** | `./devflow` |

Un nombre pelado no coincide con ninguna:

```
$ claude plugin marketplace add devflow
✘ Invalid marketplace source format. Try: owner/repo, https://..., or ./path
```

Parado dentro de la carpeta, un punto solo tampoco empieza por `./`. Usa `./` o la ruta
absoluta:

```bash
claude plugin marketplace add ./          # desde dentro de devflow/
claude plugin marketplace add ~/code/devflow
```

Si la ruta tiene la forma correcta pero la carpeta no existe, el mensaje es distinto
(`Path does not exist: <ruta>`) y te muestra contra qué ruta resolvió.

`devflow` es el nombre del plugin y `alepaper` el del marketplace — el id de instalación
siempre es `<plugin>@<marketplace>`.

Verifica que cargó de verdad:

```bash
claude plugin list                 # debe decir: devflow@alepaper  Status: ✔ enabled
claude plugin details devflow      # Component inventory → Skills (8)
```

Si `Skills` dice 0, algo no cargó. No sigas hasta que diga 8.

Dentro de una sesión funciona igual con `/plugin marketplace add ./devflow` y
`/plugin install devflow@alepaper`.

### Los comandos quedan con prefijo

```
/devflow:spec    /devflow:tasks    /devflow:autopilot    ...
```

La forma corta `/spec` también funciona **mientras nada más reclame ese nombre**. El
prefijo siempre funciona, así que es el que conviene usar si algún día instalas otro
plugin con nombres parecidos.

### Editar y probar

Con marketplace local y `source` relativo, Claude Code lee los archivos directamente de
`plugins/devflow/`. Editas una skill y:

```
/reload-plugins
```

Sin reinstalar, sin subir la versión. Esto es lo que hace cómodo iterar sobre las skills.

### Empezar de cero

```bash
claude plugin marketplace remove alepaper
```

Quita el marketplace y desinstala sus plugins.

---

## 2. Compartirlo con el equipo

Sube este repositorio a git y que cada quien corra:

```bash
claude plugin marketplace add <owner>/<repo>
claude plugin install devflow@alepaper
```

Sirve con repositorio privado. Las actualizaciones llegan subiendo la versión en
`plugins/devflow/.claude-plugin/plugin.json` y empujando el cambio.

Si solo son dos o tres personas y no quieres montar el repo, mándales el `.zip` y que
usen la vía 1 sobre la carpeta descomprimida.

---

## 3. Instalación manual, sin plugin

Copia las skills a tu directorio personal:

```bash
./install.sh
```

En Windows (PowerShell):

```powershell
$dest = "$env:USERPROFILE\.claude\skills"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item .\plugins\devflow\skills\* $dest -Recurse -Force
```

Así los comandos quedan sin prefijo (`/spec`, `/tasks`), pero pierdes `/reload-plugins`,
las actualizaciones por marketplace, y el namespace que te protege de choques de nombres.

---

## Sobre `--plugin-dir`

Funciona, pero **apuntando a la carpeta del plugin, no a la raíz del marketplace**:

```bash
claude --plugin-dir ./devflow/plugins/devflow     # ✔ carga las 8 skills
claude --plugin-dir ./devflow                     # ✘ carga vacío, sin error visible
```

Apuntado a la raíz, Claude Code no lee `marketplace.json`, así que el plugin bajo
`plugins/` nunca carga — y no muestra ningún error, que es lo que lo hace confuso.

Confirma siempre con `claude plugin details devflow` que el inventario muestre 8 skills.

Esta vía no te da `/reload-plugins` ni actualizaciones, así que sirve para una prueba
rápida, no para uso diario.

---

## Si algo falla

| Mensaje | Causa | Fix |
|---|---|---|
| `Invalid marketplace source format` | La ruta no empieza por `./`, `../`, `/` o `~` | `./devflow` desde la carpeta padre |
| `Path does not exist: <ruta>` | La forma está bien, la carpeta no está ahí | Mira la ruta del mensaje y corre el comando desde donde corresponde |
| `Marketplace file not found at <ruta>/.claude-plugin/marketplace.json` | Apuntaste a la carpeta equivocada | La raíz es la que **contiene** `.claude-plugin/`, no `plugins/devflow` |
| `Plugin "devflow" not found in marketplace "alepaper"` | El catálogo local está viejo | `claude plugin marketplace update alepaper` |
| Instaló pero `/devflow:spec` no aparece | Lo instalaste durante la sesión | `/reload-plugins` |
| `claude plugin details devflow` dice `Skills (0)` | Usaste `--plugin-dir` sobre la raíz del marketplace | Apunta a `./devflow/plugins/devflow`, o usa la vía 1 |

## Verificación final

Sea cual sea la vía:

```
/spec
```

Si el comando aparece en el menú de `/`, quedó instalado. `tdd` **no** debe aparecer: es
`user-invocable: false` a propósito, y Claude la carga sola cuando implementa.
