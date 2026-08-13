pragma Singleton
import QtQuick
QtObject {
  readonly property color base: "$base"
  readonly property color surface: "$surface0"
  readonly property color elevated: "$surface2"
  readonly property color border: "$overlay0"
  readonly property color text: "$text"
  readonly property color muted: "$subtext0"
  readonly property color accent: "$accent"
  readonly property color danger: "$red"
  readonly property int radius: $radius
  readonly property string fontFamily: "$font"
}
