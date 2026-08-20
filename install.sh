#!/usr/bin/env bash
set -euo pipefail

plugin_id="user.trackpad-gestures"
plugin_dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$plugin_id"
hypr_input="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/input.lua"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
stamp=$(date +%Y%m%d-%H%M%S)

for command_name in jq hyprctl omarchy-shell; do
  command -v "$command_name" >/dev/null 2>&1 || {
    echo "Missing required command: $command_name" >&2
    exit 1
  }
done

[[ -f $plugin_dir/manifest.json ]] || {
  echo "Clone this repository to $plugin_dir before running install.sh." >&2
  exit 1
}
[[ -f $hypr_input ]] || {
  echo "Missing Omarchy Hyprland input file: $hypr_input" >&2
  exit 1
}
[[ -f $shell_config ]] || {
  echo "Missing Omarchy shell configuration: $shell_config" >&2
  exit 1
}

cp -a "$hypr_input" "$hypr_input.bak.trackpad-gestures.$stamp"
cp -a "$shell_config" "$shell_config.bak.trackpad-gestures.$stamp"

if ! grep -Fq -- '-- user.trackpad-gestures:start' "$hypr_input"; then
  {
    printf '\n%s\n' '-- user.trackpad-gestures:start'
    printf '%s\n' 'local trackpad_gesture_config = os.getenv("HOME") .. "/.config/hypr/gestures-generated.lua"'
    printf '%s\n' 'local trackpad_gesture_loader = loadfile(trackpad_gesture_config)'
    printf '%s\n' 'if trackpad_gesture_loader then trackpad_gesture_loader() end'
    printf '%s\n' '-- user.trackpad-gestures:end'
  } >> "$hypr_input"
fi

shell_tmp="$shell_config.tmp.trackpad-gestures"
jq '
  if any(.bar.layout.right[]?; .id == "user.trackpad-gestures") then .
  else .bar.layout.right += [{"id":"user.trackpad-gestures"}]
  end
' "$shell_config" > "$shell_tmp"
mv "$shell_tmp" "$shell_config"

chmod +x "$plugin_dir/apply-gestures.sh" "$plugin_dir/screenshot-editor.sh" "$plugin_dir/uninstall.sh"
omarchy-shell shell rescanPlugins || true
hyprctl reload >/dev/null

errors=$(hyprctl configerrors)
if [[ -n $errors ]]; then
  printf '%s\n' "$errors" >&2
  exit 1
fi

echo "Trackpad Gestures installed. Click its trackpad icon in the bar to configure it."
