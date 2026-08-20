#!/usr/bin/env bash
set -euo pipefail

plugin_id="user.trackpad-gestures"
hypr_input="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/input.lua"
shell_config="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/shell.json"
generated="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/gestures-generated.lua"
stamp=$(date +%Y%m%d-%H%M%S)

[[ -f $hypr_input ]] && cp -a "$hypr_input" "$hypr_input.bak.trackpad-gestures-uninstall.$stamp"
[[ -f $shell_config ]] && cp -a "$shell_config" "$shell_config.bak.trackpad-gestures-uninstall.$stamp"

if [[ -f $hypr_input ]]; then
  sed -i '/-- user\.trackpad-gestures:start/,/-- user\.trackpad-gestures:end/d' "$hypr_input"
fi

if [[ -f $shell_config ]]; then
  shell_tmp="$shell_config.tmp.trackpad-gestures"
  jq '.bar.layout.right |= map(select(.id != "user.trackpad-gestures"))' "$shell_config" > "$shell_tmp"
  mv "$shell_tmp" "$shell_config"
fi

if [[ -f $generated ]]; then
  mv "$generated" "$generated.removed.$stamp"
fi

omarchy-shell shell rescanPlugins || true
hyprctl reload >/dev/null
hyprctl configerrors

echo "Trackpad Gestures removed from Omarchy. The repository directory was left in place."
