# Notificaciones sin herramientas

Una línea de shell. No hay nada que instalar.

## Detección y envío

```bash
MSG="T-003 lista y aprobada (3/7)"
TITLE="devflow · tarea lista"

if command -v osascript >/dev/null 2>&1; then           # macOS
  osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\""
elif command -v notify-send >/dev/null 2>&1; then        # Linux
  notify-send "$TITLE" "$MSG"
elif command -v powershell.exe >/dev/null 2>&1; then     # Windows / WSL
  powershell.exe -NoProfile -Command "New-BurntToastNotification -Text '$TITLE','$MSG'" 2>/dev/null \
    || printf '\a'
fi
printf '\a\n  >> %s - %s\n\n' "$TITLE" "$MSG"
```

La última línea siempre corre: campana de terminal más una línea visible. Es lo que
funciona en todas partes, incluso cuando la notificación nativa falla.

En Windows, `New-BurntToastNotification` requiere un módulo que puede no estar. El `||`
cae a la campana sin romper nada. No vale la pena más complejidad para un aviso.

## Webhook opcional (Slack, Discord)

Si el usuario configuró `webhook` en el frontmatter de `plan.md`:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
  -d "{\"text\":\"*$TITLE*\n$MSG\"}" "$WEBHOOK_URL" >/dev/null || true
```

El `|| true` importa: un webhook caído nunca debe tumbar el autopilot.

## Cuándo notificar

| Evento | Título |
|---|---|
| Tarea aprobada | `devflow · tarea lista` |
| Plan completo | `devflow · desarrollo completo` |
| Bloqueado, necesita decisión | `devflow · bloqueado, necesita tu decisión` |

El de bloqueo es el más importante: es el único donde el usuario tiene que hacer algo
para que el trabajo siga.

## Hooks de Claude Code

Alternativa: engancharlo al hook `Stop` en `.claude/settings.json` y que el aviso salga
solo al terminar cada turno, sin que la skill haga nada. Útil si prefieres notificaciones
consistentes en todos tus proyectos.
