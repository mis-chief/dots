import Quickshell
import Quickshell.Io
import QtQuick
import "../config"
import "../services"

// Clipboard history from cliphist. Enter copies the entry, Shift+Delete removes it.
// Everything here runs only while this view is open.
Item {
    id: root

    property var entries: []        // { id, line, preview, image: null | { ext, dims, size } }
    property bool loaded: false
    property bool missing: false    // cliphist isn't installed
    property int keepIndex: 0       // selection to restore after a reload
    property bool reloadQueued: false

    readonly property var results: {
        const q = input.text.toLowerCase().trim()
        return q === "" ? entries : entries.filter(e => e.preview.toLowerCase().includes(q))
    }

    // Image entries are decoded to files here so they can be shown. The directory is
    // emptied on every load and when the view closes: the files are full size, and
    // cliphist reuses ids after a wipe. Without a private runtime dir, no previews.
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || ""
    readonly property string thumbDir: runtimeDir === "" ? "" : runtimeDir + "/pillshell-clip"
    function thumbPath(e) { return thumbDir + "/" + e.id + "." + e.image.ext }

    // Entries go to cliphist as their list line on stdin, which every version accepts.
    readonly property string decode: 'printf "%s\\n" "$1" | cliphist decode'

    function parse(text) {
        const out = []
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 1) continue
            const id = line.slice(0, tab)
            if (!/^\d+$/.test(id)) continue
            const preview = line.slice(tab + 1)
            // cliphist lists images as: [[ binary data 42 KiB png 1920x1080 ]]
            const m = preview.match(/^\[\[ binary data (.+) (\w+) (\d+x\d+) \]\]$/)
            out.push({ id: id, line: line, preview: preview,
                       image: m ? { size: m[1], ext: m[2], dims: m[3] } : null })
        }
        return out
    }

    function copy() {
        const e = results[list.currentIndex]
        if (!e) return
        // Decode to a file first: an entry that has since left the history must not
        // replace the clipboard with nothing. Images are offered under their own
        // type rather than leaving wl-copy to guess it.
        const type = e.image ? "image/" + (e.image.ext === "jpg" ? "jpeg" : e.image.ext) : ""
        Quickshell.execDetached(["sh", "-c",
            'f=$(mktemp) || exit 1; ' + decode + ' > "$f" && [ -s "$f" ] && '
            + '{ if [ -n "$2" ]; then wl-copy --type "$2" < "$f"; else wl-copy < "$f"; fi; }; rm -f "$f"',
            "sh", e.line, type])
        PillState.close()
    }

    function remove() {
        const e = results[list.currentIndex]
        if (!e || deleter.running) return
        keepIndex = list.currentIndex
        deleter.command = ["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", e.line]
        deleter.running = true
    }

    // A reload asked for while one is running would be dropped, so it is queued.
    function reload() {
        if (lister.running) reloadQueued = true
        else lister.running = true
    }

    Process {
        id: lister
        command: ["sh", "-c",
            'command -v cliphist >/dev/null || exit 127; '
            + 'if [ -n "$1" ]; then rm -rf "$1"; mkdir -m 700 "$1"; fi; cliphist list',
            "sh", root.thumbDir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = root.parse(text)
                root.loaded = true
                Qt.callLater(() => { list.currentIndex = Math.max(0, Math.min(root.keepIndex, list.count - 1)) })
            }
        }
        onExited: code => {
            root.missing = code === 127
            if (!root.reloadQueued) return
            root.reloadQueued = false
            Qt.callLater(root.reload)
        }
    }

    Process {
        id: deleter
        onExited: root.reload()
    }

    Component.onCompleted: input.forceActiveFocus()
    Component.onDestruction: {
        if (thumbDir !== "") Quickshell.execDetached(["rm", "-rf", thumbDir])
    }

    Item {
        id: field
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
        height: 44

        Text {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: "Search clipboard history"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: 16
        }

        TextInput {
            id: input
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 16
            clip: true
            onTextChanged: list.currentIndex = 0

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) { list.incrementCurrentIndex(); event.accepted = true }
                else if (event.key === Qt.Key_Up) { list.decrementCurrentIndex(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.copy(); event.accepted = true }
                else if (event.key === Qt.Key_Escape) { PillState.close(); event.accepted = true }
                else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) { root.remove(); event.accepted = true }
            }
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Config.track
        }
    }

    Text {   // empty states
        visible: root.missing || (root.loaded && list.count === 0)
        anchors.centerIn: list
        text: root.missing ? "cliphist not found"
            : root.entries.length === 0 ? "Clipboard history is empty" : "No matches"
        color: Config.dim
        font.family: Config.font
        font.pixelSize: 13
    }

    ListView {
        id: list
        anchors { top: field.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 12 }
        clip: true
        spacing: 2
        currentIndex: 0
        highlightMoveDuration: 0

        model: ScriptModel { values: root.results }

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property var image: modelData.image
            readonly property string thumb: image && root.thumbDir !== "" ? root.thumbPath(modelData) : ""

            width: list.width
            height: image ? 88 : 40
            radius: 14
            color: ListView.isCurrentItem ? Config.track : "transparent"

            // Image rows decode their entry to a file, then show it. Only rows on
            // screen exist, so only those are decoded.
            Process {
                running: row.thumb !== ""
                command: ["sh", "-c",
                    '[ -s "$2" ] || { ' + root.decode + ' > "$2.tmp" && mv "$2.tmp" "$2"; }',
                    "sh", row.modelData.line, row.thumb]
                onExited: code => { if (code === 0) pic.source = "file://" + row.thumb }
            }

            Row {
                visible: row.image !== null
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 12

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 128; height: 72
                    Image {
                        id: pic
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        sourceSize.height: 144
                        asynchronous: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.image ? row.image.ext + " " + row.image.dims + " · " + row.image.size : ""
                    color: Config.dim
                    font.family: Config.font
                    font.pixelSize: 12
                }
            }

            Text {
                visible: row.image === null
                anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
                text: row.modelData.preview
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 13
                elide: Text.ElideRight
                maximumLineCount: 1
                textFormat: Text.PlainText
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { list.currentIndex = row.index; root.copy() }
            }
        }
    }
}
