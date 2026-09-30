#!/usr/bin/env bash
# Instalación manual (sin plugin): copia las skills a ~/.claude/skills/
# La vía recomendada es el marketplace — ver README.md.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugins/devflow"
DEST="${CLAUDE_HOME:-$HOME/.claude}"

mkdir -p "$DEST/skills"
for skill in "$SRC"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "$DEST/skills/$name"; cp -R "$skill" "$DEST/skills/$name"
  echo "  skill  $name"
done

cat <<MSG

Listo. Sin prefijo de plugin, los comandos son:

  /spec          levantar el requerimiento
  /spec-check    validar el spec con otro agente
  /breakdown         partirlo en tareas que no comparten archivos
  /autopilot     ejecutar con N agentes (dev | test | review | all | task T-00N)
  /cross-review  revisar con otro agente
  /progress      ver el estado del plan
  /tracker       conectar Linear

Empieza con:  /spec
MSG
