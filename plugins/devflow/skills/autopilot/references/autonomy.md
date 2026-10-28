# Autonomía: resolver, no aparcar

`/autopilot` corre desatendido durante horas. **Resuelve. No pregunta, y casi nunca
abandona una tarea.**

## La distinción que lo sostiene

> **Los criterios de aceptación son el contrato. El enfoque no lo es.**

Los criterios vienen del spec, que el usuario aprobó. El enfoque —qué librería, qué
estructura, qué firma exacta, en cuántos archivos— lo propuso el planificador sin haber
escrito el código todavía.

Un agente que no logra hacer funcionar el enfoque planeado **cambia el enfoque**. No
aparca. Mientras los criterios se cumplan, la tarea está bien hecha aunque no se parezca a
lo que decía el Contexto.

Casi todo lo que antes se bloqueaba cae aquí: la librería no hace lo que se pensaba, la
firma no encaja, el patrón vecino no aplica. Nada de eso es un bloqueo, es información que
solo aparece al construir.

## La escalera

Se baja un peldaño solo cuando el anterior se agotó de verdad.

**1. Reintentar.** El error es de ejecución: un import mal puesto, un mock mal armado.

**2. Cambiar el enfoque.** El camino planeado no funciona. Elige otro que cumpla los
mismos criterios, actualiza la sección Contexto de la tarea con lo que realmente hiciste, y
registra la decisión. Los criterios no se tocan.

**3. Ajustar el plan aguas abajo.** El enfoque nuevo cambia lo que las tareas dependientes
van a consumir — otra firma, otro módulo. Actualiza el Contexto de esas tareas antes de
que alguien las tome. **Sus criterios tampoco se tocan.** Registra qué cambió y por qué.

**4. Parar la corrida.** Solo cuando un **criterio de aceptación** no se puede cumplir.
Eso no es un problema de implementación: es que el spec pide algo que no se puede
construir como está escrito, y ningún cambio de enfoque lo arregla.

Los peldaños 1 a 3 son trabajo normal, no excepciones. El 4 debería ser raro, y si pasa
seguido el problema está en `/spec`, no aquí.

## Cuándo la corrida termina de verdad

No existe "aparcar y seguir" como política general: en un grafo de dependencias, abandonar
una tarea aguas arriba mata todo lo que cuelga de ella. Lo que aplica es esto:

```
tarea irresoluble
   ├── ¿tiene dependientes?
   │      sí  → no hay nada más que hacer en esa rama.
   │            Si quedan tareas listas en otras ramas, seguir con ellas.
   │            Si no quedan, la corrida TERMINA y lo reporta.
   │      no  → es una hoja: marcarla y seguir, el resto no la necesita.
```

Terminar temprano reportando por qué es honesto. Fingir que se sigue trabajando cuando no
hay nada ejecutable, no.

## El presupuesto de reintentos sigue al grafo

Abandonar una tarea cuesta lo que cuesta su descendencia. Antes de rendirte con una,
cuenta cuántas tareas dependen de ella directa o transitivamente:

| Dependientes | Presupuesto |
|---|---|
| 0 (hoja) | Normal. Abandonarla cuesta una tarea. |
| 1–2 | Doble: prueba al menos dos enfoques distintos antes de rendirte. |
| 3 o más, o es T-000 | Máximo. Agota el peldaño 3 completo. Rendirse aquí termina la corrida. |

Dedicarle la misma insistencia a una hoja que a la raíz del grafo es repartir mal el
esfuerzo de la noche.

## Lo irreversible se autoriza al arrancar

Única excepción a "resuelve tú". `git revert` deshace código; no deshace una migración que
borró una columna, ni un pago, ni datos eliminados, ni un secreto que ya salió del
repositorio. A las 3am sin nadie mirando no hay punto de retorno.

Se decide **antes**. Al iniciar, el orquestador revisa el plan contra sus puntos de parada
obligatoria y pregunta una sola vez:

```
2 tareas tocan cosas que `git revert` no deshace:

  T-004  migración que elimina la columna `usuarios.legacy_id`   (2 tareas dependen)
  T-007  borrado de registros huérfanos en producción            (hoja)

  autorizar   las ejecuto sin preguntar
  excluir     las saco de esta corrida y de lo que dependa de ellas
```

Mostrar cuántas tareas dependen de cada una importa: excluir una hoja cuesta una tarea,
excluir T-004 cuesta tres. Sin ese dato la decisión se toma a ciegas.

Si el plan no tiene ninguna, no se pregunta nada.

## `decisiones.md`

Append-only, escrito solo por el orquestador. Una entrada por decisión que el usuario no
había considerado. Las obvias no se registran: el archivo solo sirve si se lee en dos
minutos.

```markdown
## T-003 · El enfoque planeado no funcionó

**Esperado:** validar el token con la librería `jwt-simple`, según el Contexto.
**Hice:** `jose`. `jwt-simple` no soporta las claves rotativas que pide el criterio 2.
**Criterios:** los tres se cumplen, sin cambios.
**Afecta aguas abajo:** sí — actualicé el Contexto de T-005, que importaba el verificador.
**Reversible:** sí.
```

Cinco campos. **"Afecta aguas abajo"** es el que más importa por la mañana: te dice si el
cambio se quedó contenido o si se propagó por el plan.

## El reporte final

```
Plan completo: 9/9 tareas.

Decisiones tomadas sin consultarte: 3   → docs/plans/<slug>/decisiones.md
  · 2 cambios de enfoque, criterios intactos
  · 1 que se propagó: T-003 cambió la firma que consume T-005

Sin resolver: ninguna.
```

Y cuando la corrida termina antes:

```
Corrida detenida en 4/9.

T-002 no pudo cumplir el criterio "el reporte sale en menos de 2s": la consulta
tarda 8s contra el volumen real y ningún índice lo baja. Eso es el spec pidiendo
algo que no se puede construir así, no un problema de implementación.

Bloqueadas por dependencia: T-005, T-006, T-008.
Completadas: T-000, T-001, T-003, T-004.

Siguiente: decidir si el criterio de 2s cambia o si el enfoque de datos cambia.
```

Decir cuántas tareas quedaron bloqueadas por dependencia, y no solo cuál falló, es lo que
deja ver el costo real de ese criterio.

## Lo que la autonomía no relaja

- Tests antes del código, con su evidencia en la bitácora.
- Nadie aprueba su propio trabajo.
- Un commit por tarea, solo con los archivos declarados.
- La rama de integración verde después de cada merge.
- **Los criterios de aceptación.** Cambiar el enfoque es resolver; cambiar lo que la tarea
  debía lograr es construir otra cosa.

Correr sin supervisión es exactamente cuando esas garantías importan más: nadie nota el
atajo hasta la mañana siguiente.
