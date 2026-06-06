#!/bin/bash
# SwiftBar / xbar — Azure VPN Client (macOS)
# ไอคอนใน icons/ (ชื่อไฟล์ปรับได้ด้านล่าง)

#<swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

# --- ปรับแต่งได้ตามใจ ---
DEV_NAME="Development Environment"
PROD_NAME="Production Environment"
WAIT_CONNECT_SEC=60
WAIT_DISCONNECT_SEC=30

ICON_DIR=""
ICON_CACHE=""
SHOW_BAR_LABEL=true
ICON_SIZE=70
BAR_TEXT_SIZE=11

ICON_OFF_FILE="icon04.icns"
ICON_DEV_FILE="icon06.icns"
ICON_PROD_FILE="icon13.icns"
ICON_BOTH_FILE="icon13.icns"

# fallback ถ้าไม่มีไฟล์ใน icons/
ICON_OFF="⚪"
ICON_DEV="🟢"
ICON_PROD="🔵"
ICON_BOTH="🟣"

SELF="${BASH_SOURCE[0]:-$0}"
SELF="$(cd "$(dirname "$SELF")" && pwd)/$(basename "$SELF")"
ICON_DIR="${ICON_DIR:-$(dirname "$SELF")/icons}"
ICON_CACHE="${ICON_CACHE:-$ICON_DIR/.cache}"

nc_status() {
  scutil --nc status "$1" 2>/dev/null | awk 'NR==1 { print; exit }'
}

b64_encode_file() {
  base64 <"$1" | tr -d '\n'
}

# แปลง .icns → PNG ขนาดเมนูบาร์ (cache ไว้ ไม่แปลงซ้ำทุก refresh)
icns_to_png() {
  local src="$1"
  local base
  base=$(basename "$src")
  base="${base%.*}"
  local out="$ICON_CACHE/${base}-${ICON_SIZE}.png"

  mkdir -p "$ICON_CACHE"
  if [[ ! -f "$out" || "$src" -nt "$out" ]]; then
    sips -s format png "$src" --out "$out" -Z "$ICON_SIZE" >/dev/null 2>&1 || return 1
  fi
  [[ -f "$out" ]] && printf '%s\n' "$out"
}

resolve_image_file() {
  local f="$1"
  [[ -z "$f" || ! -f "$f" ]] && return 1
  case "$f" in
    *.icns) icns_to_png "$f" ;;
    *.png|*.jpg|*.jpeg|*.gif|*.webp)
      if [[ "$f" == *.gif ]]; then
        icns_to_png "$f" 2>/dev/null || return 1
      else
        printf '%s\n' "$f"
      fi
      ;;
    *) return 1 ;;
  esac
}

icon_path() {
  local name="$1"
  [[ "$name" != /* ]] && name="$ICON_DIR/$name"
  [[ -f "$name" ]] && printf '%s\n' "$name"
}

pick_icon_source() {
  local dev_up="$1" prod_up="$2"
  local file=""

  if (( dev_up && prod_up )); then
    file="$ICON_BOTH_FILE"
  elif (( dev_up )); then
    file="$ICON_DEV_FILE"
  elif (( prod_up )); then
    file="$ICON_PROD_FILE"
  else
    file="$ICON_OFF_FILE"
  fi

  icon_path "$file"
}

bar_image_param() {
  local dev_up="$1" prod_up="$2"
  local src png b64

  src=$(pick_icon_source "$dev_up" "$prod_up") || return 1
  png=$(resolve_image_file "$src") || return 1
  b64=$(b64_encode_file "$png")
  [[ -n "$b64" ]] && printf 'image=%s' "$b64"
}

wait_for_nc_status() {
  local name="$1" want="$2" max_secs="$3"
  local max=$((max_secs * 2))
  local i=0 cur=""

  while (( i < max )); do
    cur=$(nc_status "$name")
    [[ "$cur" == "$want" ]] && return 0
    if [[ "$want" == "Connected" && "$cur" == "Connecting" ]]; then
      sleep 0.5
      ((i++)) || true
      continue
    fi
    sleep 0.5
    ((i++)) || true
  done
  return 1
}

run_vpn_action() {
  local profile="$1" cmd="$2"
  local want="Disconnected"

  [[ "$cmd" == "start" ]] && want="Connected"

  /usr/sbin/scutil --nc "$cmd" "$profile" >/dev/null 2>&1 || return 1

  if [[ "$want" == "Connected" ]]; then
    wait_for_nc_status "$profile" "Connected" "$WAIT_CONNECT_SEC"
  else
    wait_for_nc_status "$profile" "Disconnected" "$WAIT_DISCONNECT_SEC"
  fi
}

case "${1:-}" in
  start-dev)  run_vpn_action "$DEV_NAME"  start; exit $? ;;
  stop-dev)   run_vpn_action "$DEV_NAME"  stop;  exit $? ;;
  start-prod) run_vpn_action "$PROD_NAME" start; exit $? ;;
  stop-prod)  run_vpn_action "$PROD_NAME" stop;  exit $? ;;
esac

dev_state=$(nc_status "$DEV_NAME")
prod_state=$(nc_status "$PROD_NAME")

dev_up=0
prod_up=0
[[ "$dev_state" == "Connected" ]] && dev_up=1
[[ "$prod_state" == "Connected" ]] && prod_up=1

bar_icon="$ICON_OFF"
bar_text="Off"

if (( dev_up && prod_up )); then
  bar_icon="$ICON_BOTH"
  bar_text="Dev + Prod"
elif (( dev_up )); then
  bar_icon="$ICON_DEV"
  bar_text="Dev"
elif (( prod_up )); then
  bar_icon="$ICON_PROD"
  bar_text="Prod"
fi

img_param=$(bar_image_param "$dev_up" "$prod_up" || true)

if [[ -n "$img_param" ]]; then
  if [[ "$SHOW_BAR_LABEL" == true ]]; then
    echo "${bar_text} | ${img_param} size=${BAR_TEXT_SIZE}"
  else
    echo "| ${img_param}"
  fi
else
  echo "${bar_icon} ${bar_text} | size=${BAR_TEXT_SIZE}"
fi

echo "---"
echo "Development: ${dev_state:-unknown} | color=$([[ $dev_up -eq 1 ]] && echo green || echo gray)"
echo "Production: ${prod_state:-unknown} | color=$([[ $prod_up -eq 1 ]] && echo green || echo gray)"
echo "---"

if (( dev_up )); then
  echo "Disconnect Development | bash=$SELF param1=stop-dev terminal=false refresh=true"
else
  echo "Connect Development | bash=$SELF param1=start-dev terminal=false refresh=true"
fi

if (( prod_up )); then
  echo "Disconnect Production | bash=$SELF param1=stop-prod terminal=false refresh=true"
else
  echo "Connect Production | bash=$SELF param1=start-prod terminal=false refresh=true"
fi

echo "---"
echo "Open Azure VPN Client | bash=/usr/bin/open param1=-a param2='Azure VPN Client' terminal=false"
echo "Refresh | refresh=true"
