import Quickshell
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// A tray item's menu, drawn inside the pill (no separate popup window, so
// nothing fights the click-away grab). Covers the control center while open.
Rectangle {
    id: root

    property var item: null          // SystemTrayItem
    property var stack: []           // submenu entries opened on top of the root menu
    signal dismissed()

    color: Config.bg
    onItemChanged: stack = []

    readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item?.menu ?? null)
    readonly property string heading: stack.length > 0 ? stack[stack.length - 1].text
        : (item?.title || item?.tooltipTitle || item?.id || "")

    function back() {
        if (stack.length > 0) stack = stack.slice(0, -1)
        else dismissed()
    }

    QsMenuOpener { id: opener; menu: root.current }

    MouseArea { anchors.fill: parent }   // swallow clicks so nothing underneath fires

    ColumnLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            IconButton { name: "back"; size: 18; onClicked: root.back() }
            Text {
                Layout.fillWidth: true
                text: root.heading
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: opener.children

            delegate: Item {
                id: row
                required property var modelData   // QsMenuEntry
                width: list.width
                height: modelData.isSeparator ? 9 : 40

                Rectangle {
                    visible: row.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width - 24
                    height: 1
                    color: Config.track
                }

                Rectangle {
                    visible: !row.modelData.isSeparator
                    anchors.fill: parent
                    radius: 14
                    color: hit.containsMouse && row.modelData.enabled ? Config.track : "transparent"
                    opacity: row.modelData.enabled ? 1 : 0.4

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 10

                        Item {   // check / radio state, only for entries that have one
                            visible: row.modelData.buttonType !== QsMenuButtonType.None
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            Icon {
                                anchors.centerIn: parent
                                visible: row.modelData.checkState === Qt.Checked
                                name: "check"
                                size: 16
                                color: Config.accent
                            }
                        }
                        Image {
                            visible: source != "" && status === Image.Ready
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            sourceSize: Qt.size(32, 32)
                            source: row.modelData.icon
                            asynchronous: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.text
                            color: Config.fg
                            font.family: Config.font
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Icon {
                            visible: row.modelData.hasChildren
                            name: "chevronRight"
                            size: 14
                            color: Config.dim
                        }
                    }

                    MouseArea {
                        id: hit
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: row.modelData.enabled
                        onClicked: {
                            if (row.modelData.hasChildren) {
                                root.stack = root.stack.concat([row.modelData])
                            } else {
                                row.modelData.triggered()
                                root.dismissed()
                                PillState.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
