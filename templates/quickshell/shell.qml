import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ShellRoot {
  id: root
  property bool controlVisible: false

  IpcHandler {
    target: "controlCenter"
    function toggle(): void { root.controlVisible = !root.controlVisible }
  }
  IpcHandler {
    target: "settings"
    function toggle(): void { root.controlVisible = !root.controlVisible }
  }
  IpcHandler {
    target: "hotkeys"
    function toggle(): void {
      root.controlVisible = true;
      settingsCenter.openTab(4);
    }
  }

  SettingsCenter {
    id: settingsCenter
    requestedVisible: root.controlVisible
    onCloseRequested: root.controlVisible = false
  }
}
