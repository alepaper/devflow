# Revisores externos

La revisión vale más cuando la hace **otro modelo**, no solo otro contexto. Un modelo
distinto falla distinto, así que ve lo que el que escribió el código no puede ver.

Se configura en el frontmatter de `plan.md`:

```yaml
reviewer: codex exec --skip-git-repo-check -
```

---

## Codex (recomendado)

```yaml
reviewer: codex exec --skip-git-repo-check -
```

El `-` final le dice que lea el prompt por stdin. Se invoca así:

```bash
codex exec --skip-git-repo-check - < prompt.md | tee revision.md
```

---

## Gemini CLI

```yaml
reviewer: gemini -p
```

Toma el prompt como argumento en vez de stdin:

```bash
gemini -p "$(cat prompt.md)" | tee revision.md
```

---

## Cualquier otro CLI

El contrato es mínimo: recibe el prompt (por stdin o como argumento), escribe la
respuesta a stdout, y esa respuesta contiene una línea
`VERDICT: APPROVED|CHANGES_REQUESTED|BLOCKED`.

Si tu herramienta necesita flags de no-interactividad, ponlos en el valor de `reviewer`.

---

## Subagente de Claude (fallback)

```yaml
reviewer: subagente
```

Sin CLI externo, un subagente con contexto limpio es el fallback. Es más débil: mismo
modelo, mismos puntos ciegos estructurales. Pero es muchísimo mejor que auto-revisarse,
porque no ve el razonamiento que produjo el código.

Reglas cuando usas subagente:

- Le pasas **solo** el archivo de prompt. Nunca la conversación de implementación.
- Nunca le dices que el código lo escribió otro agente tuyo, ni que "ya está casi listo".
- El subagente no puede editar código. Solo emite veredicto.

---

## Qué NO cuenta como revisión

- El mismo agente releyendo su código "con ojos frescos"
- Un prompt nuevo en la misma conversación
- Correr los tests otra vez
- Un linter

Ninguno detecta "este test pasaría con una implementación vacía", que es justo el tipo de
error que la revisión existe para atrapar.

---

## Verifica que el revisor está vivo

**Antes** de arrancar el autopilot, no después de cinco tareas:

```bash
printf 'Responde únicamente con este bloque, sin nada más:\n\nVERDICT: APPROVED\nBLOCKERS:\nNITS:\n' \
  | codex exec --skip-git-repo-check -
```

Debe salir una línea `VERDICT: APPROVED`. Si no, arregla el comando antes de empezar.
