import QtQuick 2.15

Rectangle {
  id: root
  width: 1920
  height: 1080
  color: "#000000"
  property color foreground: "#F5F5F5"
  property color muted: "#A6ADC8"
  property color accent: "#CBA6F7"
  property color surface: "#15151D"
  property int selectedSession: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

  function authenticate() {
    status.text = "Signing in…"
    status.color = muted
    sddm.login(username.text, password.text, selectedSession)
  }

  Column {
    anchors.centerIn: parent
    width: Math.min(460, parent.width - 48)
    spacing: 24
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "BLACK MOCHA"; color: root.foreground; font.family: "Noto Sans"; font.pixelSize: 34; font.bold: true; font.letterSpacing: 4 }
    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Sign in to your desktop"; color: root.muted; font.family: "Noto Sans"; font.pixelSize: 17 }
    Item { width: 1; height: 10 }

    Column {
      width: parent.width; spacing: 8
      Text { text: "USERNAME"; color: root.muted; font.pixelSize: 12; font.bold: true }
      Rectangle {
        width: parent.width; height: 58; radius: 10; color: root.surface
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: parent.width; height: username.activeFocus ? 3 : 1; color: username.activeFocus ? root.accent : "#45475A" }
        TextInput {
          id: username
          anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
          color: root.foreground; selectionColor: root.accent; selectedTextColor: "#000000"
          verticalAlignment: TextInput.AlignVCenter; font.family: "Noto Sans"; font.pixelSize: 19
          text: userModel.lastUser; clip: true
          KeyNavigation.tab: password
          Keys.onReturnPressed: password.forceActiveFocus()
        }
      }
    }

    Column {
      width: parent.width; spacing: 8
      Text { text: "PASSWORD"; color: root.muted; font.pixelSize: 12; font.bold: true }
      Rectangle {
        width: parent.width; height: 58; radius: 10; color: root.surface
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: parent.width; height: password.activeFocus ? 3 : 1; color: password.activeFocus ? root.accent : "#45475A" }
        TextInput {
          id: password
          anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
          color: root.foreground; selectionColor: root.accent; selectedTextColor: "#000000"
          verticalAlignment: TextInput.AlignVCenter; font.family: "Noto Sans"; font.pixelSize: 19
          echoMode: TextInput.Password; passwordCharacter: "•"; clip: true
          KeyNavigation.tab: loginButton
          Keys.onReturnPressed: root.authenticate()
        }
      }
    }

    Column {
      width: parent.width; spacing: 8
      Text { text: "SESSION"; color: root.muted; font.pixelSize: 12; font.bold: true }
      ListView {
        width: parent.width; height: 46; orientation: ListView.Horizontal; spacing: 8; clip: true; model: sessionModel
        delegate: Rectangle {
          width: Math.max(150, sessionName.implicitWidth + 32); height: 42; radius: 8
          color: index === root.selectedSession ? root.accent : root.surface
          Text { id: sessionName; anchors.centerIn: parent; text: name; color: index === root.selectedSession ? "#000000" : root.foreground; font.family: "Noto Sans"; font.pixelSize: 15; font.bold: index === root.selectedSession }
          MouseArea { anchors.fill: parent; onClicked: root.selectedSession = index }
        }
      }
    }

    Rectangle {
      id: loginButton
      width: parent.width; height: 58; radius: 10; color: loginMouse.pressed ? "#B4BEFE" : root.accent
      activeFocusOnTab: true
      Text { anchors.centerIn: parent; text: "SIGN IN"; color: "#000000"; font.family: "Noto Sans"; font.pixelSize: 18; font.bold: true }
      MouseArea { id: loginMouse; anchors.fill: parent; onClicked: root.authenticate() }
      Keys.onReturnPressed: root.authenticate()
      Keys.onSpacePressed: root.authenticate()
    }

    Text { id: status; width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Select Hyprland (uwsm-managed)"; color: root.muted; font.family: "Noto Sans"; font.pixelSize: 14; wrapMode: Text.WordWrap }
    Row {
      anchors.horizontalCenter: parent.horizontalCenter; spacing: 36
      Text { text: "RESTART"; color: restartMouse.containsMouse ? root.foreground : root.muted; font.pixelSize: 14; font.bold: true; MouseArea { id: restartMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.reboot() } }
      Text { text: "SHUT DOWN"; color: powerMouse.containsMouse ? root.foreground : root.muted; font.pixelSize: 14; font.bold: true; MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; onClicked: sddm.powerOff() } }
    }
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      status.text = "Login failed — check username and password"
      status.color = "#F38BA8"
      password.text = ""
      password.forceActiveFocus()
    }
  }
  Component.onCompleted: { if (username.text.length > 0) password.forceActiveFocus(); else username.forceActiveFocus() }
}
