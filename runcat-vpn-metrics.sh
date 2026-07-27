#!/bin/bash
# RunCat Neo custom metrics producer — Azure VPN Client (macOS)
#
# Writes VPN status as strict JSON for RunCat Neo Custom Metrics.
# RunCat only watches the JSON file; use launchd or another scheduler to run this script.

set -euo pipefail

DEV_NAME="${DEV_NAME:-Development Environment}"
PROD_NAME="${PROD_NAME:-Production Environment}"
OUTPUT_FILE="${RUNCAT_VPN_OUTPUT_FILE:-$HOME/.runcat/azure-vpn.json}"

nc_status() {
  /usr/sbin/scutil --nc status "$1" 2>/dev/null | awk 'NR==1 { print; exit }'
}

json_escape() {
  local s="${1:-}"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

status_value() {
  local state="${1:-unknown}"
  [[ -n "$state" ]] && printf '%s' "$state" || printf 'unknown'
}

normalized_status() {
  local state="${1:-}"
  [[ "$state" == "Connected" ]] && printf '1' || printf '0'
}

mkdir -p "$(dirname "$OUTPUT_FILE")"

dev_state="$(status_value "$(nc_status "$DEV_NAME")")"
prod_state="$(status_value "$(nc_status "$PROD_NAME")")"

metrics_bar_value="Off"
if [[ "$dev_state" == "Connected" && "$prod_state" == "Connected" ]]; then
  metrics_bar_value="Dev+Prod"
elif [[ "$dev_state" == "Connected" ]]; then
  metrics_bar_value="Dev"
elif [[ "$prod_state" == "Connected" ]]; then
  metrics_bar_value="Prod"
fi

last_updated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
tmp_file="${OUTPUT_FILE}.tmp.$$"

{
  printf '{\n'
  printf '  "title": "Azure VPN",\n'
  printf '  "symbol": "network",\n'
  printf '  "metricsBarValue": "%s",\n' "$(json_escape "$metrics_bar_value")"
  printf '  "metrics": [\n'
  printf '    { "title": "Development", "formattedValue": "%s", "normalizedValue": %s },\n' \
    "$(json_escape "$dev_state")" "$(normalized_status "$dev_state")"
  printf '    { "title": "Production", "formattedValue": "%s", "normalizedValue": %s }\n' \
    "$(json_escape "$prod_state")" "$(normalized_status "$prod_state")"
  printf '  ],\n'
  printf '  "lastUpdatedDate": "%s"\n' "$last_updated"
  printf '}\n'
} >"$tmp_file"

mv "$tmp_file" "$OUTPUT_FILE"
printf '%s\n' "$OUTPUT_FILE"
