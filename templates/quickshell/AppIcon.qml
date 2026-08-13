import QtQuick
Text {
  property string iconName: ""
  property string fallbackName: "settings"
  property int iconSize: 18
  readonly property var glyphs: ({
    settings: 0xf013, appearance: 0xf1fc, palette: 0xf53f, apps: 0xf00a,
    hotkeys: 0xf11c, wallpaper: 0xf03e, system: 0xf108, add: 0xf067,
    delete: 0xf1f8, network: 0xf1eb, bluetooth: 0xf293, audio: 0xf028,
    "audio-muted": 0xf6a9, cpu: 0xf2db, memory: 0xf538,
    temperature: 0xf2c9, battery: 0xf242, "battery-charging": 0xf0e7,
    reload: 0xf2f1, save: 0xf0c7, close: 0xf00d, previous: 0xf060,
    random: 0xf074, next: 0xf061, diagnostics: 0xf188
  })
  text: String.fromCodePoint(glyphs[fallbackName] || glyphs.settings)
  font.family: fallbackName === "bluetooth" ? "Font Awesome 7 Brands" : "Font Awesome 7 Free"
  font.weight: Font.Black
  font.pixelSize: iconSize
  color: Theme.text
  width: iconSize
  height: iconSize
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
