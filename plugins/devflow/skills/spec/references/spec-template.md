# Plantilla de spec

Guarda esto en `docs/plans/<slug>/spec.md`. Todo en español.

```markdown
---
plan: <slug>
titulo: <Nombre legible del requerimiento>
estado: borrador          # borrador | aprobado
creado: YYYY-MM-DD
aprobado_en:
validado_con: []          # auditoria | escenarios | spec-check
spec_check:               # LISTO | HUECOS | BLOQUEADO
---

# <Título>

## Resumen
Un párrafo. Qué se construye y para quién. Si alguien solo lee esto, debe entender el
alcance.

## Usuario
Quién lo usa, con qué frecuencia, con qué nivel técnico.

## Problema
Qué pasa hoy sin esto y qué cuesta. Concreto, no abstracto.

## Éxito medible
Señales observables, no adjetivos. Cada criterio debe pasar esta prueba:
**¿podrían dos personas estar en desacuerdo sobre si se cumplió?** Si sí, reescríbelo.

- [ ] <número, evento o comportamiento visible>
- [ ] <...>

## Alcance
Lo que sí entra en esta versión.

- <capacidad 1>
- <capacidad 2>

## Fuera de alcance
Obligatorio. Lo que explícitamente NO se construye ahora.

- <no-objetivo 1>
- <no-objetivo 2>

## Restricciones
Stack, deadline, presupuesto, sistemas que no se pueden romper, decisiones ya tomadas.

| Restricción | Por qué existe |
|---|---|
| | |

## Datos
Qué lee, qué escribe, qué no se puede perder nunca, dónde vive.

## Términos
Los sustantivos del dominio que el documento usa, definidos. Si "usuario autorizado"
aparece sin definición, dos ingenieros lo van a construir distinto.

| Término | Qué significa exactamente |
|---|---|
| | |

## Casos borde
Los modos de falla que el usuario ya mencionó, que se descubrieron en la entrevista, o
que salieron de los escenarios de validación.

- <caso 1> → comportamiento esperado
- <caso 2> → comportamiento esperado

## Escenarios validados
Las situaciones concretas que se le pasaron al usuario antes de aprobar, con su
respuesta. Son la evidencia de que el spec se puso a prueba y no solo se leyó.

| Escenario | Qué debe pasar |
|---|---|
| | |

## Dependencias externas
Lo que este trabajo asume que existe y no controla: APIs, datos, accesos, equipos.
Cada una marcada como confirmada o no.

| Dependencia | ¿Confirmada? | Quién la provee |
|---|---|---|
| | | |

## Definición de terminado
El estándar que toda tarea de este plan debe cumplir antes de contar como lista.

- [ ] Tests automatizados que prueban el comportamiento (no la implementación)
- [ ] Suite completa en verde
- [ ] Build sin errores
- [ ] Revisado y aprobado por un agente distinto al que escribió el código
- [ ] Commit propio y descriptivo
- [ ] <lo que el usuario haya agregado en la entrevista>

## Preguntas abiertas
Lo que sigue sin resolver y necesita decisión humana antes o durante el plan.

- [ ] <pregunta>
```
