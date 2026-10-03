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
de cambiar a un modelo más capaz.

## El momento de cambiar a un modelo más ligero

Al terminar `/breakdown`, no antes. Es cuando las decisiones caras ya se tomaron —
partición, matriz de archivos, grafo de dependencias — y lo que queda en la sesión es
coordinación: repartir tareas, parsear reportes de seis líneas, mergear en orden.

El orquestador corre durante todo el plan, así que el ahorro se acumula por cada tarea.

**Uno más ligero, no el más barato que haya.** El orquestador sigue decidiendo si un conflicto de merge
es defecto de planeación, si una suite roja tras merge limpio es conflicto semántico, y si
una tarea que rebota tres veces está mal especificada. Eso es juicio, y un modelo del piso
lo deja pasar.

Vale cambiarlo de vuelta por uno más capaz para: replanear, un conflicto semántico, o una
tarea que rebota en revisión.

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
