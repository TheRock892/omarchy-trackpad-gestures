import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "user.trackpad-gestures"
  ipcTarget: "user.trackpad-gestures"

  readonly property string helperPath: Quickshell.env("HOME") + "/.config/omarchy/plugins/user.trackpad-gestures/apply-gestures.sh"
  readonly property var directions: [
    { key: "left", label: "Swipe left" },
    { key: "right", label: "Swipe right" },
    { key: "up", label: "Swipe up" },
    { key: "down", label: "Swipe down" },
    { key: "pinchin", label: "Pinch in" },
    { key: "pinchout", label: "Pinch out" }
  ]
  readonly property var actionOptions: [
    { value: "none", label: "None", description: "Do nothing" },
    { value: "workspace", label: "Switch workspace", description: "Move continuously between workspaces" },
    { value: "relative_workspace", label: "Relative workspace", description: "Reliably move next or previous through empty workspaces" },
    { value: "focus", label: "Focus window", description: "Focus a window in the gesture direction" },
    { value: "move", label: "Move window", description: "Move the active window" },
    { value: "resize", label: "Resize window", description: "Resize the active window" },
    { value: "special", label: "Special workspace", description: "Toggle the special workspace" },
    { value: "close", label: "Close window", description: "Close the active window" },
    { value: "fullscreen", label: "Fullscreen", description: "Toggle fullscreen" },
    { value: "maximize", label: "Maximize", description: "Toggle maximized mode" },
    { value: "float", label: "Float window", description: "Put the active window in floating mode" },
    { value: "tile", label: "Tile window", description: "Put the active window in tiled mode" },
    { value: "cursor_zoom", label: "Cursor zoom", description: "Continuously zoom around the cursor" },
    { value: "scroll_move", label: "Scroll layout", description: "Move through the scrolling layout" },
    { value: "expose", label: "Expose", description: "Toggle window overview (like macOS Exposé)" },
    { value: "custom_command", label: "Custom command", description: "Run an arbitrary shell command" }
  ]
  readonly property var clickOptions: [
    { value: "clickfinger", label: "Finger count", description: "Two-finger press is right-click" },
    { value: "buttonareas", label: "Button areas", description: "Press the lower-right area to right-click" }
  ]
  readonly property var tapOptions: [
    { value: "lrm", label: "2 fingers = right", description: "One left, two right, three capture" },
    { value: "lmr", label: "3 fingers = right", description: "One left, two middle, three right" }
  ]
  readonly property var captureTriggerOptions: [
    { value: "none", label: "None", description: "Keep normal mouse-button behavior" },
    { value: "twofinger", label: "2-finger click", description: "Replaces normal right-click" },
    { value: "threefinger", label: "3-finger click", description: "Replaces normal middle-click" },
    { value: "buttonarea", label: "Lower-right button area", description: "Replaces normal right-click" }
  ]
  readonly property var captureActionOptions: [
    { value: "screenshot", label: "Screenshot", description: "Open the smart screenshot selector" },
    { value: "record", label: "Screen recording", description: "Start or stop screen recording" }
  ]

  // Safe first-run preset. Saved shell.json values override these after install.
  readonly property var installationDefaults: ({
    enabled: true,
    selectedFingers: 3,
    clickMethod: "clickfinger",
    tapMap: "lrm",
    captureTrigger: "threefinger",
    captureAction: "screenshot",
    screenshotEditor: false,
    f2_left: "none",
    f2_right: "none",
    f2_up: "none",
    f2_down: "none",
    f2_pinchin: "none",
    f2_pinchout: "none",
    f3_left: "none",
    f3_right: "none",
    f3_up: "none",
    f3_down: "none",
    f3_pinchin: "none",
    f3_pinchout: "none",
    f4_left: "none",
    f4_right: "none",
    f4_up: "none",
    f4_down: "none",
    f4_pinchin: "none",
    f4_pinchout: "none"
  })

  readonly property bool gesturesEnabled: setting("enabled", installationDefaults.enabled) === true
  readonly property int selectedFingerIndex: Math.max(0, Math.min(2, Number(setting("selectedFingers", installationDefaults.selectedFingers)) - 2))
  readonly property var visibleDirections: selectedFingerIndex === 0 ? directions.slice(4) : directions
  readonly property string captureTrigger: String(setting("captureTrigger", installationDefaults.captureTrigger))
  readonly property string captureAction: String(setting("captureAction", installationDefaults.captureAction))
  readonly property bool screenshotEditor: setting("screenshotEditor", installationDefaults.screenshotEditor) === true
  property string statusText: ""
  property bool initializing: true

  function defaultAction(fingers, direction) {
    return String(installationDefaults["f" + fingers + "_" + direction] || "none")
  }

  function gestureValue(fingers, direction) {
    return String(setting("f" + fingers + "_" + direction, defaultAction(fingers, direction)))
  }

  function customCommandValue(fingers, direction) {
    return String(setting("cmd_f" + fingers + "_" + direction, ""))
  }

  function setCustomCommand(fingers, direction, command) {
    var values = {}
    values["cmd_f" + fingers + "_" + direction] = command
    persist(values)
  }

  function persist(values) {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    for (var changed in values) entry[changed] = values[changed]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    applyTimer.restart()
  }

  function applyCommand() {
    var command = [helperPath,
      gesturesEnabled ? "true" : "false",
      String(setting("clickMethod", installationDefaults.clickMethod)),
      String(setting("tapMap", installationDefaults.tapMap)),
      captureTrigger,
      captureAction,
      screenshotEditor ? "true" : "false"]
    for (var fingers = 2; fingers <= 4; fingers++)
      for (var i = 0; i < directions.length; i++)
        command.push(gestureValue(fingers, directions[i].key))

    // Build custom commands payload (newline-separated key|command pairs)
    var customParts = []
    for (var fingers = 2; fingers <= 4; fingers++) {
      for (var i = 0; i < directions.length; i++) {
        var action = gestureValue(fingers, directions[i].key)
        if (action === "custom_command") {
          var cmd = customCommandValue(fingers, directions[i].key)
          if (cmd !== "") {
            customParts.push(fingers + "_" + directions[i].key + "|" + cmd)
          }
        }
      }
    }
    if (customParts.length > 0) {
      command.push(customParts.join("\n"))
    }

    return command
  }

  function applyNow() {
    if (applyProcess.running) {
      applyTimer.restart()
      return
    }
    statusText = "Applying…"
    applyProcess.command = applyCommand()
    applyProcess.running = true
  }

  function setGesture(fingers, direction, action) {
    var values = {}
    values["f" + fingers + "_" + direction] = action
    persist(values)
  }

  function setCaptureTrigger(value) {
    var values = { captureTrigger: value }
    if (value === "twofinger" || value === "threefinger") values.clickMethod = "clickfinger"
    else if (value === "buttonarea") values.clickMethod = "buttonareas"
    persist(values)
  }

  function open() {
    root.controller.show()
    Qt.callLater(function() { root.initializing = false })
  }

  onSettingsChanged: if (!initializing) applyTimer.restart()

  Component.onCompleted: {
    initializing = false
    applyTimer.start()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: applyProcess
    stdout: StdioCollector { onStreamFinished: {} }
    stderr: StdioCollector {
      onStreamFinished: if (text.trim() !== "") root.statusText = text.trim()
    }
    onExited: function(exitCode) {
      root.statusText = exitCode === 0 ? "Saved and applied" : "Could not apply configuration"
    }
  }

  Timer {
    id: applyTimer
    interval: 350
    repeat: false
    onTriggered: root.applyNow()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰟸"
    tooltipText: root.gesturesEnabled ? "Trackpad gestures enabled\nClick to configure" : "Trackpad gestures disabled\nClick to configure"
    dimmed: !root.gesturesEnabled
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.LeftButton) root.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    contentWidth: popup.fittedContentWidth(Style.space(600))
    contentHeight: popup.fittedContentHeight(Style.space(650), Style.space(700))

    Flickable {
      anchors.fill: parent
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        Text {
          text: "Trackpad gestures"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Toggle {
          width: parent.width
          label: "Enable gestures"
          description: "Turn every configured swipe and pinch on or off"
          checked: root.gesturesEnabled
          foreground: root.barForeground
          onClicked: root.persist({ enabled: !root.gesturesEnabled })
        }

        Row {
          width: parent.width
          spacing: Style.space(8)
          Repeater {
            model: [2, 3, 4]
            delegate: Button {
              required property int modelData
              width: (content.width - Style.space(16)) / 3
              text: modelData + " fingers"
              active: root.selectedFingerIndex === modelData - 2
              onClicked: root.persist({ selectedFingers: modelData })
            }
          }
        }

        Text {
          text: (root.selectedFingerIndex + 2) + "-finger assignments"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Text {
          visible: root.selectedFingerIndex === 0
          width: parent.width
          text: "2 finger gestures are reserved for normal trackpad scrolling on a page. Pinch in and pinch out can still be assigned below."
          color: Qt.darker(root.barForeground, 1.25)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Repeater {
          model: root.visibleDirections
          delegate: Item {
            required property var modelData
            width: content.width
            height: picker.implicitHeight + (root.gestureValue(root.selectedFingerIndex + 2, modelData.key) === "custom_command" ? cmdField.implicitHeight + Style.space(8) : 0)

            SearchableDropdown {
              id: picker
              width: parent.width
              label: modelData.label
              value: root.gestureValue(root.selectedFingerIndex + 2, modelData.key)
              options: root.actionOptions
              foreground: root.barForeground
              placeholderText: "Choose an action"
              onChanged: function(value) { root.setGesture(root.selectedFingerIndex + 2, modelData.key, value) }
            }

            TextField {
              id: cmdField
              anchors.top: picker.bottom
              anchors.topMargin: Style.space(8)
              width: parent.width
              visible: root.gestureValue(root.selectedFingerIndex + 2, modelData.key) === "custom_command"
              placeholderText: "Enter command (e.g. alacritty)"
              text: root.customCommandValue(root.selectedFingerIndex + 2, modelData.key)
              foreground: root.barForeground
              accent: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              onTextChanged: root.setCustomCommand(root.selectedFingerIndex + 2, modelData.key, text)
            }
          }
        }

        PanelSeparator { width: parent.width }

        Text {
          text: "Trackpad clicks"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        SearchableDropdown {
          width: parent.width
          label: "Physical click method"
          value: String(root.setting("clickMethod", root.installationDefaults.clickMethod))
          options: root.clickOptions
          foreground: root.barForeground
          onChanged: function(value) { root.persist({ clickMethod: value }) }
        }

        SearchableDropdown {
          width: parent.width
          label: "Tap mapping"
          value: String(root.setting("tapMap", root.installationDefaults.tapMap))
          options: root.tapOptions
          foreground: root.barForeground
          onChanged: function(value) { root.persist({ tapMap: value }) }
        }

        PanelSeparator { width: parent.width }

        Text {
          text: "Capture click"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        SearchableDropdown {
          width: parent.width
          label: "Trigger"
          value: root.captureTrigger
          options: root.captureTriggerOptions
          foreground: root.barForeground
          onChanged: function(value) { root.setCaptureTrigger(value) }
        }

        SearchableDropdown {
          width: parent.width
          label: "Action"
          value: root.captureAction
          options: root.captureActionOptions
          foreground: root.barForeground
          onChanged: function(value) { root.persist({ captureAction: value }) }
        }

        Toggle {
          visible: root.captureAction === "screenshot"
          width: parent.width
          label: "Open screenshot editor"
          description: "Open your Tensaku editor after taking the screenshot"
          checked: root.screenshotEditor
          foreground: root.barForeground
          onClicked: root.persist({ screenshotEditor: !root.screenshotEditor })
        }

        Text {
          visible: root.captureTrigger !== "none"
          width: parent.width
          text: root.captureTrigger === "threefinger"
            ? "This replaces normal middle-click while enabled."
            : "This replaces normal right-click while enabled."
          color: Qt.darker(root.barForeground, 1.25)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: root.statusText || "Changes apply automatically"
          color: Qt.darker(root.barForeground, 1.35)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
