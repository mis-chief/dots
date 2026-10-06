import QtQuick
import "../config"

// Nerd Font glyph. Use `name` (see Glyphs.map) or pass a code point via `code`.
Item {
    id: root
    property string name
    property int code: 0
    property color color: Config.fg
    property real size: 20

    implicitWidth: size
    implicitHeight: size

    Text {
        anchors.centerIn: parent
        text: String.fromCodePoint(root.code > 0 ? root.code : (Glyphs.map[root.name] ?? 0x20))
        color: root.color
        font.family: Config.iconFont
        font.pixelSize: root.size
    }
}
