#!/usr/bin/env bash
set -euo pipefail

if command -v omarchy-screenshot-edit >/dev/null 2>&1; then
  exec omarchy-screenshot-edit smart
fi

# Omarchy's standard smart screenshot flow opens its configured editor.
exec omarchy-capture-screenshot smart
