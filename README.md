# Omarchy Trackpad Gestures

A Quickshell bar widget for configuring Hyprland trackpad gestures on Omarchy.

The popup configures 2-, 3-, and 4-finger swipes and pinches, toggles all gestures, changes click/tap mappings, and assigns a trackpad click to screenshots or screen recording. Changes persist in `~/.config/omarchy/shell.json` and apply live through a generated `~/.config/hypr/gestures-generated.lua` file.

## Requirements

- Omarchy 4 or newer
- Hyprland 0.55 or newer with Lua configuration
- `git` and `jq`

## Install

```bash
git clone https://github.com/mpweaver/omarchy-trackpad-gestures.git ~/.config/omarchy/plugins/user.trackpad-gestures
~/.config/omarchy/plugins/user.trackpad-gestures/install.sh
```

The installer backs up `~/.config/hypr/input.lua` and `~/.config/omarchy/shell.json`, adds the plugin to the right side of the bar, and reloads Hyprland. It is safe to run again.

## First-run preset

- Two-finger pinch: cursor zoom
- Three-finger swipes: focus windows in each direction
- Three-finger pinch in/out: none
- Four-finger left/right swipe: relative next/previous workspace
- Four-finger vertical swipe: fullscreen
- One-finger tap: left-click
- Two-finger tap: right-click
- Three-finger tap: screenshot capture
- Screenshot editor: on

The Relative workspace action uses a discrete `r+1` step going forward and an `m-1` step going back. Unlike Hyprland's continuous workspace action, it can leave an empty workspace instead of becoming stuck there.

Every value can be changed from the popup after installation.

## Capture warning

Trackpads expose finger clicks as ordinary mouse buttons. Assigning two-finger click or the lower-right button area to capture replaces normal right-click. Assigning three-finger click replaces normal middle-click.

When the screenshot-editor toggle is enabled, the plugin uses `omarchy-screenshot-edit` if installed and otherwise opens Omarchy's standard smart screenshot flow.

## Update

```bash
git -C ~/.config/omarchy/plugins/user.trackpad-gestures pull --ff-only
~/.config/omarchy/plugins/user.trackpad-gestures/install.sh
```

## Uninstall

```bash
~/.config/omarchy/plugins/user.trackpad-gestures/uninstall.sh
```

Afterward, remove `~/.config/omarchy/plugins/user.trackpad-gestures` if you no longer want the source checkout.

## License

MIT
