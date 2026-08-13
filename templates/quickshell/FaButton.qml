import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
  id: control
  property string iconKey: "settings"
  contentItem: RowLayout {
    spacing: 7
    AppIcon { fallbackName: control.iconKey; iconSize: 15 }
    Text {
      text: control.text
      color: Theme.text
      font.family: Theme.fontFamily
      verticalAlignment: Text.AlignVCenter
    }
  }
}
