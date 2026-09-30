# Formato de tarea

Un archivo por tarea en `docs/plans/<slug>/breakdown/T-00N.md`. En modo Linear, el mismo
contenido va en el cuerpo del issue.

```markdown
---
id: T-003
titulo: Un usuario puede iniciar sesión
estado: pending          # pending | in_progress | in_review | changes_requested | blocked | done
depende_de: [T-001]
tamano: M                # XS | S | M | L
linear: null             # ID del issue cuando el tracker es Linear
---

# T-003 · Un usuario puede iniciar sesión

## Qué logra
Un párrafo. Qué cambia para el usuario final cuando esta tarea esté lista.

## Criterios de aceptación
Observables y verificables. Máximo 3. Si necesitas más, la tarea es dos tareas.

- [ ] POST /login con credenciales válidas devuelve 200 y una sesión firmada
- [ ] Credenciales inválidas devuelven 401 sin revelar si el email existe
- [ ] La sesión expira a los 30 días

## Tests que lo prueban
Escribe estos ANTES del código. Son el contrato.

- [ ] `login_exitoso_devuelve_sesion`
- [ ] `login_con_password_incorrecta_devuelve_401`
- [ ] `login_con_email_inexistente_devuelve_401_mismo_mensaje`
- [ ] `sesion_expirada_es_rechazada`

## Verificación
- [ ] Tests enfocados: `<comando de test de la tarea>`
- [ ] Suite completa en verde: `<comando de test>`
- [ ] Build limpio: `<comando de build>`

## Archivos que va a tocar
Declararlos por adelantado es lo que evita que dos agentes choquen.

- `src/auth/login.ts`
- `tests/auth/login.test.ts`

## Notas de contexto
Patrones existentes que seguir, decisiones ya tomadas, trampas conocidas.

## Bitácora
Se llena durante la ejecución. Append-only.

- `2026-09-14T10:02Z` A1 tomó la tarea
- `2026-09-14T10:41Z` A1: 4 tests en verde, build ok, commit `a3f9c21`
- `2026-09-14T10:52Z` codex: CHANGES_REQUESTED — falta rate limiting en login
- `2026-09-14T11:10Z` A1: rate limiting agregado, commit `b81d004`
- `2026-09-14T11:18Z` codex: APPROVED
```

## Reglas

- **Máximo 3 criterios de aceptación.** Más significa que es más de una tarea.
- **Los archivos declarados son un contrato.** Si una tarea necesita tocar un archivo que
  no declaró y otra tarea activa sí lo declaró, para y avisa — no edites a ciegas.
- **La bitácora nunca se reescribe.** Solo se agregan líneas al final.
- **Este archivo ES el estado.** El campo `estado` del frontmatter es la verdad. Lo
  escribe únicamente el agente asignado a esta tarea; ningún otro archivo del plan se
  toca. Linear, si está configurado, es el espejo.
