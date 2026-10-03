# Elección de modelos

Dos decisiones distintas, y solo una la controla devflow.

| Fase | Quién la decide |
|---|---|
| `/spec`, `/spec-check`, `/breakdown` | **Tú**, con `/model`. Corren en la sesión principal; una skill no puede cambiar el modelo de su propia sesión |
| Agentes de implementación y revisión | **devflow**, vía el campo `model` del subagente |

Por eso esto es una recomendación con una pregunta, no una detección. **No inspecciones
el entorno, no busques claves de API, no leas la configuración del usuario.** Pregunta y
acepta la respuesta.

## La pregunta

Una vez por proyecto, breve, saltable:

```
Para los agentes de implementación, ¿qué modelo uso? (sugerido: sonnet)
Valores válidos: opus, sonnet, haiku, un ID completo, o inherit.

Nota: el modelo de /spec y /breakdown es el de tu sesión. Si quieres el más
capaz para planear, cámbialo tú con /model — yo no puedo.
```

Si no quiere decidir, `inherit` y seguir. Nunca frenar un proyecto por una optimización
de costo.

## Recomendación

| Fase | Nivel | Por qué |
|---|---|---|
| `/spec` | el más capaz | Un requerimiento mal entendido se propaga a todo lo demás |
| `/spec-check` | el más capaz | Busca lo que nadie escribió; es la tarea más difícil del flujo |
| `/breakdown` | el más capaz | La matriz de archivos y el grafo de dependencias deciden si el paralelismo funciona |
| Implementación | medio | Si las tareas llegan bien escritas |
| Revisión | otro proveedor | `codex` o `gemini` antes que otro nivel del mismo modelo |

**El nivel de implementación depende de qué tan buenas sean tus tareas.** Una tarea con
rutas concretas, firmas reales y los tests ya listados la ejecuta bien un modelo medio.
Una tarea vaga obliga al agente a decidir diseño, y ahí lo barato produce código que hay
que rehacer.

Si `/cross-review` empieza a devolver `CHANGES_REQUESTED` seguido, revisa las tareas antes
de subir el modelo.

## Dónde se guarda

Frontmatter de `plan.md`:

```yaml
modelo_implementacion: sonnet     # opus | sonnet | haiku | <id> | inherit
```

`/breakdown` lo arrastra desde un plan anterior del proyecto. No se vuelve a preguntar.

## Límites

- devflow no cambia el modelo de la sesión principal.
- Si `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` está activa, Claude Code ignora el campo `model`
  de todos los subagentes. Si el usuario lo menciona, dilo; no lo salgas a buscar.
- Para costos, `/cost` y `/usage`. devflow no estima precios.
