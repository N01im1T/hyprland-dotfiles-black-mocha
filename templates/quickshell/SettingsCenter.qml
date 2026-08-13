import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
  id: window
  property bool requestedVisible: false
  property var configData: null
  property string statusText: "Loading settings…"
  property bool busy: false
  signal closeRequested()

  visible: requestedVisible
  focusable: true
  aboveWindows: true
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  color: "#B0000000"

  onRequestedVisibleChanged: if (requestedVisible) loadConfig()

  function runProcess(process, command) {
    if (process.running) return;
    process.command = command;
    process.running = true;
  }

  function openTab(index) {
    navigation.currentIndex = index;
  }

  function loadConfig() {
    busy = true;
    statusText = "Loading settings…";
    runProcess(loadProcess, ["dotctl", "config", "export"]);
  }

  function fillModels() {
    keybindModel.clear();
    for (let bind of configData.keybinds) {
      keybindModel.append({
        keys: bind.keys || "",
        command: bind.command || "",
        dispatcher: bind.dispatcher || "",
        setting: bind.setting || "",
        description: bind.description || "",
        category: bind.category || "Other"
      });
    }
    paletteModel.clear();
    for (let name in configData.theme.colors)
      paletteModel.append({ colorName: name, colorValue: configData.theme.colors[name] });

    themeName.text = configData.settings.theme.name;
    accent.text = configData.settings.theme.accent;
    background.text = configData.settings.theme.background;
    textColor.text = configData.settings.theme.text;
    fontName.text = configData.settings.theme.font;
    profile.currentIndex = Math.max(0, profile.model.indexOf(configData.profile));
    scale.currentIndex = Math.max(0, scale.model.indexOf(configData.settings.desktop.scale));
    bottomBar.checked = configData.settings.desktop.bottom_bar;
    radiusSmall.value = configData.settings.appearance.radius_small;
    radiusMedium.value = configData.settings.appearance.radius_medium;
    radiusLarge.value = configData.settings.appearance.radius_large;
    radiusXlarge.value = configData.settings.appearance.radius_xlarge;
    borderWidth.value = configData.settings.appearance.border_width;
    gapsInner.value = configData.settings.appearance.gaps_inner;
    gapsOuter.value = configData.settings.appearance.gaps_outer;
    blurEnabled.checked = configData.settings.appearance.blur;
    shadowEnabled.checked = configData.settings.appearance.shadows;
    animationEnabled.checked = configData.settings.animations.enabled;
    animationSpeed.value = configData.settings.animations.speed;
    wallpaperDirectory.text = configData.settings.wallpaper.directory;
    wallpaperTransition.text = configData.settings.wallpaper.transition;
    wallpaperDuration.value = configData.settings.wallpaper.transition_duration;
    terminalCommand.text = configData.settings.commands.terminal;
    filesCommand.text = configData.settings.commands.file_manager;
    browserCommand.text = configData.settings.commands.browser;
    editorCommand.text = configData.settings.commands.editor;
    launcherCommand.text = configData.settings.commands.launcher;
    controlCommand.text = configData.settings.commands.control_center;
    hotkeysCommand.text = configData.settings.commands.hotkeys;
    emojiCommand.text = configData.settings.commands.emoji_picker;
    textEditorCommand.text = configData.settings.commands.text_editor;
    writerCommand.text = configData.settings.commands.office_writer;
    spreadsheetCommand.text = configData.settings.commands.office_spreadsheet;
    vpnCommand.text = configData.settings.commands.vpn;
    torBrowserCommand.text = configData.settings.commands.tor_browser;
    wallpaperModel.clear();
    for (let path of configData.wallpapers) wallpaperModel.append({ pathValue: path });
  }

  function collectConfig() {
    let result = JSON.parse(JSON.stringify(configData));
    result.settings.theme = {
      name: themeName.text, accent: accent.text, background: background.text,
      text: textColor.text, font: fontName.text
    };
    result.profile = profile.currentText;
    result.settings.desktop.profile = profile.currentText;
    result.settings.desktop.scale = scale.currentText;
    result.settings.desktop.bottom_bar = bottomBar.checked;
    result.settings.appearance = {
      radius_small: radiusSmall.value, radius_medium: radiusMedium.value,
      radius_large: radiusLarge.value, radius_xlarge: radiusXlarge.value,
      border_width: borderWidth.value, gaps_inner: gapsInner.value,
      gaps_outer: gapsOuter.value, blur: blurEnabled.checked, shadows: shadowEnabled.checked
    };
    result.settings.animations = { enabled: animationEnabled.checked, speed: animationSpeed.value };
    result.settings.wallpaper = {
      directory: wallpaperDirectory.text, transition: wallpaperTransition.text,
      transition_duration: wallpaperDuration.value
    };
    result.settings.commands = {
      terminal: terminalCommand.text, file_manager: filesCommand.text,
      browser: browserCommand.text, editor: editorCommand.text,
      launcher: launcherCommand.text, control_center: controlCommand.text,
      hotkeys: hotkeysCommand.text, emoji_picker: emojiCommand.text,
      text_editor: textEditorCommand.text, office_writer: writerCommand.text,
      office_spreadsheet: spreadsheetCommand.text, vpn: vpnCommand.text,
      tor_browser: torBrowserCommand.text
    };
    result.theme.colors = {};
    for (let p = 0; p < paletteModel.count; ++p) {
      let colorEntry = paletteModel.get(p);
      result.theme.colors[colorEntry.colorName] = colorEntry.colorValue;
    }
    result.keybinds = [];
    for (let i = 0; i < keybindModel.count; ++i) {
      let entry = keybindModel.get(i);
      let bind = { keys: entry.keys, description: entry.description, category: entry.category };
      if (entry.setting) bind.setting = entry.setting;
      if (entry.command) bind.command = entry.command;
      if (entry.dispatcher) bind.dispatcher = entry.dispatcher;
      result.keybinds.push(bind);
    }
    return result;
  }

  function saveConfig() {
    busy = true;
    statusText = "Validating and applying…";
    runProcess(saveProcess, ["dotctl", "config", "save", JSON.stringify(collectConfig())]);
  }

  Process {
    id: loadProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          window.configData = JSON.parse(text);
          window.fillModels();
          window.statusText = "Settings loaded";
        } catch (error) {
          window.statusText = "Unable to read settings: " + error;
        }
        window.busy = false;
      }
    }
    stderr: StdioCollector { onStreamFinished: if (text.trim()) window.statusText = text.trim() }
  }

  Process {
    id: saveProcess
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          let response = JSON.parse(text);
          window.statusText = response.ok ? "Saved and applied successfully" : "Save failed";
          if (response.ok) window.loadConfig();
        } catch (error) { window.statusText = text.trim() || String(error); }
        window.busy = false;
      }
    }
    stderr: StdioCollector { onStreamFinished: if (text.trim()) { window.statusText = text.trim(); window.busy = false; } }
  }

  Process { id: actionProcess; stdout: StdioCollector { onStreamFinished: window.statusText = text.trim() || "Done" } }

  ListModel { id: keybindModel }
  ListModel { id: paletteModel }
  ListModel { id: wallpaperModel }

  component SectionTitle: Label {
    color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 18; font.bold: true
    Layout.fillWidth: true; Layout.topMargin: 8
  }
  component FieldLabel: Label {
    color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 12
    Layout.preferredWidth: 190
  }
  component ConfigField: TextField {
    color: Theme.text; font.family: Theme.fontFamily; selectByMouse: true
    Layout.fillWidth: true
    background: Rectangle { color: Theme.surface; border.color: parent.activeFocus ? Theme.accent : Theme.border; radius: 8 }
  }
  component ConfigSwitch: Switch {
    font.family: Theme.fontFamily; palette.text: Theme.text; palette.windowText: Theme.text
  }
  component NumberControl: SpinBox {
    editable: true; from: 0; to: 100; font.family: Theme.fontFamily
    palette.text: Theme.text; palette.base: Theme.surface; palette.button: Theme.elevated
  }
  component FormRow: RowLayout {
    property alias label: rowLabel.text
    default property alias content: slot.data
    Layout.fillWidth: true; spacing: 16
    FieldLabel { id: rowLabel }
    RowLayout { id: slot; Layout.fillWidth: true }
  }

  Rectangle {
    width: Math.min(parent.width - 48, 1180)
    height: Math.min(parent.height - 48, 780)
    anchors.centerIn: parent
    radius: 20
    color: Theme.base
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 14

      RowLayout {
        Layout.fillWidth: true
        ColumnLayout {
          Layout.fillWidth: true; spacing: 2
          Label { text: "Black Mocha Settings"; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: 24; font.bold: true }
          Label { text: "Single control center for the complete desktop configuration"; color: Theme.muted; font.family: Theme.fontFamily }
        }
        FaButton { text: "Reload"; iconKey: "reload"; enabled: !window.busy; onClicked: window.loadConfig() }
        FaButton { text: "Save & Apply"; iconKey: "save"; enabled: !window.busy && window.configData !== null; onClicked: window.saveConfig() }
        FaButton { text: "Close"; iconKey: "close"; onClicked: window.closeRequested() }
      }

      RowLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16
        Rectangle {
          Layout.preferredWidth: 190; Layout.fillHeight: true; radius: 14; color: Theme.surface; border.color: Theme.border
          ListView {
            id: navigation
            anchors.fill: parent; anchors.margins: 8
            model: [
              { label: "General", icon: "preferences-system", fallback: "settings" },
              { label: "Appearance", icon: "preferences-desktop-theme", fallback: "appearance" },
              { label: "Palette", icon: "preferences-color", fallback: "palette" },
              { label: "Applications", icon: "application-x-executable", fallback: "apps" },
              { label: "Hotkeys", icon: "input-keyboard", fallback: "hotkeys" },
              { label: "Wallpapers", icon: "preferences-desktop-wallpaper", fallback: "wallpaper" },
              { label: "System", icon: "utilities-system-monitor", fallback: "system" }
            ]
            spacing: 4
            delegate: Rectangle {
              required property var modelData; required property int index
              width: ListView.view.width; height: 44; radius: 9
              color: navigation.currentIndex === index ? Theme.elevated : "transparent"
              Row {
                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; spacing: 10
                AppIcon { iconName: modelData.icon; fallbackName: modelData.fallback; iconSize: 18 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label; color: navigation.currentIndex === index ? Theme.accent : Theme.text; font.family: Theme.fontFamily }
              }
              MouseArea { anchors.fill: parent; onClicked: navigation.currentIndex = index }
            }
          }
        }

        StackLayout {
          currentIndex: navigation.currentIndex
          Layout.fillWidth: true; Layout.fillHeight: true

          ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
              width: parent.width; spacing: 12
              SectionTitle { text: "General" }
              FormRow { label: "Theme name"; ConfigField { id: themeName } }
              FormRow { label: "Accent (#RRGGBB)"; ConfigField { id: accent } }
              FormRow { label: "Background"; ConfigField { id: background } }
              FormRow { label: "Text"; ConfigField { id: textColor } }
              FormRow { label: "Font"; ConfigField { id: fontName } }
              FormRow { label: "Visual profile"; ComboBox { id: profile; model: ["performance", "balanced", "beautiful"]; Layout.fillWidth: true } }
              FormRow { label: "Display scale"; ComboBox { id: scale; model: ["auto", "1.0", "1.25", "1.5", "2.0"]; Layout.fillWidth: true } }
              FormRow { label: "Bottom taskbar"; ConfigSwitch { id: bottomBar } }
            }
          }

          ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
              width: parent.width; spacing: 12
              SectionTitle { text: "Shape and spacing" }
              FormRow { label: "Small radius"; NumberControl { id: radiusSmall } }
              FormRow { label: "Medium radius"; NumberControl { id: radiusMedium } }
              FormRow { label: "Large radius"; NumberControl { id: radiusLarge } }
              FormRow { label: "Extra-large radius"; NumberControl { id: radiusXlarge } }
              FormRow { label: "Border width"; NumberControl { id: borderWidth; to: 5 } }
              FormRow { label: "Inner gaps"; NumberControl { id: gapsInner; to: 40 } }
              FormRow { label: "Outer gaps"; NumberControl { id: gapsOuter; to: 60 } }
              SectionTitle { text: "Effects" }
              FormRow { label: "Blur"; ConfigSwitch { id: blurEnabled } }
              FormRow { label: "Shadows"; ConfigSwitch { id: shadowEnabled } }
              FormRow { label: "Animations"; ConfigSwitch { id: animationEnabled } }
              FormRow { label: "Animation speed"; Slider { id: animationSpeed; from: 0.25; to: 3.0; stepSize: 0.05; Layout.fillWidth: true }; Label { text: animationSpeed.value.toFixed(2) + "×"; color: Theme.text } }
            }
          }

          ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
              width: parent.width; spacing: 8
              SectionTitle { text: "Complete color palette" }
              Label { text: "Use #RRGGBB values. Changes propagate to every generated component."; color: Theme.muted; font.family: Theme.fontFamily }
              Repeater {
                model: paletteModel
                RowLayout {
                  Layout.fillWidth: true
                  Rectangle { width: 28; height: 28; radius: 7; color: colorValue; border.color: Theme.border }
                  FieldLabel { text: colorName }
                  ConfigField { text: colorValue; onTextChanged: paletteModel.setProperty(index, "colorValue", text) }
                }
              }
            }
          }

          ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
              width: parent.width; spacing: 12
              SectionTitle { text: "Default applications and shell actions" }
              FormRow { label: "Terminal"; ConfigField { id: terminalCommand } }
              FormRow { label: "File manager"; ConfigField { id: filesCommand } }
              FormRow { label: "Browser"; ConfigField { id: browserCommand } }
              FormRow { label: "Editor"; ConfigField { id: editorCommand } }
              FormRow { label: "Launcher"; ConfigField { id: launcherCommand } }
              FormRow { label: "Control center"; ConfigField { id: controlCommand } }
              FormRow { label: "Hotkeys popup"; ConfigField { id: hotkeysCommand } }
              FormRow { label: "Emoji picker"; ConfigField { id: emojiCommand } }
              FormRow { label: "Text editor"; ConfigField { id: textEditorCommand } }
              FormRow { label: "Document editor"; ConfigField { id: writerCommand } }
              FormRow { label: "Spreadsheet editor"; ConfigField { id: spreadsheetCommand } }
              FormRow { label: "VPN client"; ConfigField { id: vpnCommand } }
              FormRow { label: "Private browser"; ConfigField { id: torBrowserCommand } }
            }
          }

          ColumnLayout {
            spacing: 10
            RowLayout {
              Layout.fillWidth: true
              SectionTitle { text: "Hotkeys" }
              FaButton { text: "Add"; iconKey: "add"; onClicked: keybindModel.append({keys: "SUPER +", command: "", dispatcher: "", setting: "", description: "New action", category: "Other"}) }
            }
            Label { text: "One list generates Hyprland bindings, UI help and Markdown documentation."; color: Theme.muted; font.family: Theme.fontFamily }
            ListView {
              Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8; clip: true
              model: keybindModel
              delegate: Rectangle {
                required property int index
                width: ListView.view.width; height: 164; radius: 12; color: Theme.surface; border.color: Theme.border
                GridLayout {
                  anchors.fill: parent; anchors.margins: 10; columns: 4; columnSpacing: 8; rowSpacing: 6
                  ConfigField { text: keys; placeholderText: "Keys"; onTextChanged: keybindModel.setProperty(index, "keys", text) }
                  ConfigField { text: description; placeholderText: "Description"; onTextChanged: keybindModel.setProperty(index, "description", text) }
                  ConfigField { text: category; placeholderText: "Category"; onTextChanged: keybindModel.setProperty(index, "category", text) }
                  FaButton { text: "Remove"; iconKey: "delete"; onClicked: keybindModel.remove(index) }
                  ConfigField { Layout.columnSpan: 2; text: command; placeholderText: "Command (leave empty for dispatcher)"; onTextChanged: keybindModel.setProperty(index, "command", text) }
                  ConfigField { Layout.columnSpan: 2; text: dispatcher; placeholderText: "Dispatcher"; onTextChanged: keybindModel.setProperty(index, "dispatcher", text) }
                  ConfigField { Layout.columnSpan: 4; text: setting; placeholderText: "Linked command: terminal, browser, launcher… (optional)"; onTextChanged: keybindModel.setProperty(index, "setting", text) }
                }
              }
            }
          }

          ColumnLayout {
            spacing: 10
            SectionTitle { text: "Wallpapers" }
            FormRow { label: "Directory"; ConfigField { id: wallpaperDirectory } }
            FormRow { label: "Transition"; ConfigField { id: wallpaperTransition } }
            FormRow { label: "Duration"; Slider { id: wallpaperDuration; from: 0; to: 5; stepSize: 0.05; Layout.fillWidth: true }; Label { text: wallpaperDuration.value.toFixed(2) + "s"; color: Theme.text } }
            RowLayout {
              FaButton { text: "Previous"; iconKey: "previous"; onClicked: runProcess(actionProcess, ["dotctl", "wallpaper", "previous"]) }
              FaButton { text: "Random"; iconKey: "random"; onClicked: runProcess(actionProcess, ["dotctl", "wallpaper", "random"]) }
              FaButton { text: "Next"; iconKey: "next"; onClicked: runProcess(actionProcess, ["dotctl", "wallpaper", "next"]) }
            }
            GridView {
              Layout.fillWidth: true; Layout.fillHeight: true; cellWidth: 190; cellHeight: 126; clip: true
              model: wallpaperModel
              delegate: Rectangle {
                width: 180; height: 116; radius: 12; color: Theme.surface; border.color: Theme.border; clip: true
                Image { anchors.fill: parent; source: "file://" + pathValue; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 30; color: "#B0000000" }
                Text { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 7; text: pathValue.split("/").pop(); elide: Text.ElideMiddle; color: Theme.text; font.family: Theme.fontFamily }
                MouseArea { anchors.fill: parent; onClicked: runProcess(actionProcess, ["dotctl", "wallpaper", "set", pathValue]) }
              }
            }
          }

          ScrollView {
            contentWidth: availableWidth
            ColumnLayout {
              width: parent.width; spacing: 12
              SectionTitle { text: "System and diagnostics" }
              Label { text: configData ? "Device: " + (configData.hardware.device || "unknown") + " · GPU: " + (configData.hardware.gpu || "unknown") : ""; color: Theme.text; font.family: Theme.fontFamily }
              RowLayout {
                FaButton { text: "Diagnostics"; iconKey: "diagnostics"; onClicked: runProcess(actionProcess, ["dotctl", "doctor"]) }
                FaButton { text: "Waybar"; iconKey: "reload"; onClicked: runProcess(actionProcess, ["dotctl", "restart", "waybar"]) }
                FaButton { text: "Quickshell"; iconKey: "reload"; onClicked: runProcess(actionProcess, ["dotctl", "restart", "quickshell"]) }
                FaButton { text: "Network"; iconKey: "network"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
                FaButton { text: "Bluetooth"; iconKey: "bluetooth"; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                FaButton { text: "Audio"; iconKey: "audio"; onClicked: Quickshell.execDetached(["pavucontrol"]) }
              }
              Label { text: "Configuration files: ~/.config/black-mocha\nGenerated components are updated atomically through dotctl."; color: Theme.muted; font.family: Theme.fontFamily }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        BusyIndicator { running: window.busy; visible: running; implicitWidth: 22; implicitHeight: 22 }
        Label { Layout.fillWidth: true; text: window.statusText; color: window.statusText.indexOf("Invalid") >= 0 || window.statusText.indexOf("failed") >= 0 ? Theme.danger : Theme.muted; font.family: Theme.fontFamily; elide: Text.ElideRight }
        Label { text: "SUPER + A"; color: Theme.accent; font.family: Theme.fontFamily }
      }
    }
  }
}
