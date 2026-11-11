#!/usr/bin/env bash
# Deterministic checks of silWeb's rules (AGENTS.md / AGENTS.full.md).
# Adapted from the rails-code-review validate_rules.sh of the work projects:
# same idea (fast grep sweep before the human-like review), silWeb's rules.
#
# Usage (from the project root):
#   validate_rules.sh                 # whole app/, spec/ and db/migrate
#   validate_rules.sh FILE...         # only these files (e.g. the slice diff)
#
# VIOLATION = breaks a project rule (exit code 1).
# AVISO     = needs a human look; may be legitimate.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 0 ]; then
  FILES=$(printf '%s\n' "$@" | while read -r f; do [ -f "$f" ] && echo "$f"; done)
else
  FILES=$( { git ls-files app spec db/migrate; git ls-files --others --exclude-standard app spec db/migrate; } | sort -u)
fi

FAILED=0
WARNED=0
if [ -t 1 ]; then R=$'\033[0;31m' Y=$'\033[0;33m' G=$'\033[0;32m' N=$'\033[0m'; else R='' Y='' G='' N=''; fi
red()    { printf '%s%s%s\n' "$R" "$*" "$N"; }
yellow() { printf '%s%s%s\n' "$Y" "$*" "$N"; }
green()  { printf '%s%s%s\n' "$G" "$*" "$N"; }

# subset <path regex> [exclude regex]
subset() { echo "$FILES" | grep -E "$1" | { if [ -n "${2:-}" ]; then grep -Ev "$2"; else cat; fi; } || true; }

# check <VIOLATION|AVISO> <name> <grep -E pattern> <files>
check() {
  local level="$1" name="$2" pattern="$3" files="$4" matches=""
  [ -n "$files" ] && matches=$(echo "$files" | xargs -r grep -nHE "$pattern" 2>/dev/null)
  if [ -z "$matches" ]; then
    green "  OK         $name"
  elif [ "$level" = VIOLATION ]; then
    FAILED=$((FAILED + 1)); red "  VIOLATION  $name"; echo "$matches" | sed 's/^/             /'
  else
    WARNED=$((WARNED + 1)); yellow "  AVISO      $name"; echo "$matches" | sed 's/^/             /'
  fi
}

echo "Reglas de silWeb — $(echo "$FILES" | grep -c . ) archivo(s)"
echo

echo "== Arquitectura"
CONTROLLERS=$(subset '^app/controllers/.*\.rb$' 'concerns/authentication\.rb$')
MODELS=$(subset '^app/models/.*\.rb$' 'application_record\.rb$')
SERVICES_NO_SEARCH=$(subset '^app/services/.*\.rb$' '/search\.rb$')
check VIOLATION "Controllers sin consultas ni escrituras de ActiveRecord (Silvalde/NoActiveRecordInControllers)" \
  '\b[A-Z][A-Za-z]*(::[A-Z][A-Za-z]*)*\.(find|find_by!?|where|all|create!?|update!?|destroy_all|delete_all|exists\?|pluck|count|first|last|authenticate_by)\b' "$CONTROLLERS"
check VIOLATION "Modelos sin scopes ni default_scope (Silvalde/NoQueriesInModels)" \
  '^\s*(scope|default_scope)\b' "$MODELS"
check AVISO "Services de caso de uso que consultan sin pasar por <Dominio>::Search" \
  '\b[A-Z][A-Za-z]*(::[A-Z][A-Za-z]*)*\.(where|find_by!?|find|all|exists\?|pluck|order|joins|count|first|last)\b' "$SERVICES_NO_SEARCH"
check AVISO "Métodos de modelo con parámetros (la regla: métodos sin parámetros sobre su estado)" \
  '^\s+def (\w+[!?]?)\(' "$MODELS"
check VIOLATION "Vistas, decorators y helpers sin consultas" \
  '\.(where|find_by!?|find|pluck|joins|includes)\(' "$(subset '^app/(views|decorators|helpers)/')"
check AVISO "Vistas, decorators y helpers que llaman a un Search (los datos deberían llegar del controller)" \
  'Search\.' "$(subset '^app/(views|decorators|helpers)/')"

echo
echo "== Errores y seguridad"
RUBY_APP=$(subset '^app/.*\.rb$')
check VIOLATION "Sin rescue genérico (rescue a secas, StandardError o Exception)" \
  '(^\s*rescue\s*($|=>)|rescue\s+(StandardError|Exception)\b|rescue\s*nil|\brescue\s+[a-z_]+\s*$)' "$RUBY_APP"
check VIOLATION "Sin permit! (mass assignment)" '\bpermit!' "$(subset '^app/controllers/')"
check AVISO "Hash de params pasado entero a un service" '\.call\(\s*params\s*[,)]' "$(subset '^app/controllers/')"
check VIOLATION "Interpolación dentro de SQL (usa placeholders ?)" \
  '\.(where|order|joins|select|having|find_by_sql|exists\?)\(\s*"[^"]*#\{' "$(subset '^app/.*\.rb$')"
check AVISO "html_safe / raw (riesgo de XSS)" '(\.html_safe\b|\braw\()' "$(subset '^app/')"

echo
echo "== Frontend e i18n"
VIEWS=$(subset '^app/views/.*\.erb$' '\.(xml|json)\.erb$|^app/views/layouts/mailer')
check AVISO "IDs de DOM a mano (usa dom_id)" \
  '(id: *"[a-z_]+_#\{|id="[a-z_]+_<%=|"[a-z_]+_#\{[a-z_.]+\.id\}")' "$(subset '^app/(views|controllers)/')"
check AVISO "Texto visible sin t() en vistas" \
  '>[^<>%{}]*[A-Za-zÁÉÍÓÚáéíóúÑñ]{3,}[^<>%{}]*</' "$VIEWS"
check AVISO "Flash o render con texto literal en controllers" \
  '(notice|alert):\s*"[A-Za-z]' "$CONTROLLERS"

echo
echo "== Base de datos"
MIGRATIONS=$(subset '^db/migrate/' 'active_storage')
check AVISO "Migraciones que borran, renombran o cambian columnas (¿plan en fases?)" \
  '\b(remove_column|rename_column|change_column|drop_table)\b' "$MIGRATIONS"
check AVISO "Dinero o cantidades como float/decimal (silWeb guarda céntimos en integer)" \
  '\bt\.(float|decimal)\b|, *:(float|decimal)\b' "$MIGRATIONS"
check AVISO "Referencias sin índice propio (comprueba que un índice compuesto empiece por esa columna)" 'index: *false' "$MIGRATIONS"

echo
echo "== Tests"
check VIOLATION "Sin tests desactivados o enfocados (xit, fit, focus, skip, pending)" \
  '^\s*(xit|xdescribe|xcontext|fit|fdescribe|fcontext)\b|focus: *true|^\s*(skip|pending)\b' "$(subset '^spec/.*_spec\.rb$')"

echo
echo "== i18n (claves usadas y paridad es/en)"
if ruby "$SCRIPT_DIR/check_i18n.rb" . | sed 's/^/  /'; [ "${PIPESTATUS[0]}" -ne 0 ]; then
  FAILED=$((FAILED + 1))
fi

echo
echo "================================"
if [ "$FAILED" -eq 0 ]; then
  green "0 violaciones, $WARNED aviso(s) a revisar"
else
  red "$FAILED violación(es), $WARNED aviso(s) — revisa la salida"
fi
exit $(( FAILED > 0 ))
