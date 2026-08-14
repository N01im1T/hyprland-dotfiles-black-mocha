import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
  id: root
  width: 1920
  height: 1080
  color: config.stringValue("background") || "#000000"

  property color accent: config.stringValue("accent") || "#CBA6F7"
  property color surface: config.stringValue("surface") || "#11111B"
  property color foreground: config.stringValue("text") || "#CDD6F4"
  property color muted: config.stringValue("muted") || "#A6ADC8"
  property color danger: config.stringValue("error") || "#F38BA8"

  function authenticate() {
    message.text = "Signing in…"
    sddm.login(username.text, password.text, session.currentIndex)
  }

  Rectangle {
    anchors.centerIn: parent
    width: Math.min(520, parent.width - 48)
    height: 610
    radius: 28
    color: root.surface
    border.width: 2
    border.color: root.accent

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 48
      spacing: 18

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 72
        height: 72
        radius: 36
        color: root.accent
        Text {
          anchors.centerIn: parent
          text: "BM"
          color: "#000000"
          font.family: "Noto Sans"
          font.pixelSize: 24
          font.bold: true
        }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "BLACK MOCHA"
        color: root.foreground
        font.family: "Noto Sans"
        font.pixelSize: 30
        font.bold: true
        font.letterSpacing: 3
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: "Welcome back"
        color: root.muted
        font.family: "Noto Sans"
        font.pixelSize: 16
      }

      TextField {
        id: username
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        text: userModel.lastUser
        placeholderText: "Username"
        color: root.foreground
        placeholderTextColor: root.muted
        selectByMouse: true
        font.pixelSize: 17
        background: Rectangle {
          radius: 12
          color: "#181825"
          border.width: username.activeFocus ? 2 : 1
          border.color: username.activeFocus ? root.accent : "#45475A"
        }
      }

      TextField {
        id: password
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        placeholderText: "Password"
        color: root.foreground
        placeholderTextColor: root.muted
        echoMode: TextInput.Password
        passwordCharacter: "•"
        font.pixelSize: 17
        Keys.onReturnPressed: root.authenticate()
        background: Rectangle {
          radius: 12
          color: "#181825"
          border.width: password.activeFocus ? 2 : 1
          border.color: password.activeFocus ? root.accent : "#45475A"
        }
      }

      ComboBox {
        id: session
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
        font.pixelSize: 16
        palette.window: "#181825"
        palette.base: "#181825"
        palette.button: "#181825"
        palette.text: root.foreground
        palette.buttonText: root.foreground
        palette.highlight: root.accent
        palette.highlightedText: "#000000"
      }

      Button {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        text: "Sign in"
        onClicked: root.authenticate()
        contentItem: Text {
          text: parent.text
          color: "#000000"
          font.pixelSize: 18
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { radius: 12; color: root.accent }
      }

      Text {
        id: message
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "Select Hyprland (uwsm-managed), then sign in"
        color: root.muted
        font.pixelSize: 14
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 28
        Button {
          text: "Restart"
          flat: true
          contentItem: Text { text: parent.text; color: root.foreground; font.pixelSize: 15 }
          onClicked: sddm.reboot()
        }
        Button {
          text: "Shut down"
          flat: true
          contentItem: Text { text: parent.text; color: root.foreground; font.pixelSize: 15 }
          onClicked: sddm.powerOff()
        }
      }
    }
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      message.text = "Incorrect username or password"
      message.color = root.danger
      password.text = ""
      password.forceActiveFocus()
    }
  }

  Component.onCompleted: {
    if (username.text.length > 0) password.forceActiveFocus()
    else username.forceActiveFocus()
  }
}
