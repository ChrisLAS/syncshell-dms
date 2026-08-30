import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "models/PanelModel.js" as PanelModel

PluginComponent {
    id: root

    property var state: pluginService && pluginService.getGlobalVar
        ? pluginService.getGlobalVar(pluginId, "state", ({})) : ({})
    property var folderRows: state && state.folderRows ? state.folderRows : []
    readonly property real indexedBytes: PanelModel.total(folderRows, "globalBytes")
    readonly property real remainingBytes: PanelModel.total(folderRows, "needBytes")
    readonly property int activeFolders: {
        var count = 0
        for (var i = 0; i < folderRows.length; i++)
            if (folderRows[i].syncing || folderRows[i].scanning) count++
        return count
    }
    readonly property int problemFolders: {
        var count = 0
        for (var i = 0; i < folderRows.length; i++) if (folderRows[i].problem) count++
        return count
    }

    Connections {
        target: pluginService
        function onGlobalVarChanged(changedPluginId, name) {
            if (changedPluginId === root.pluginId && name === "state")
                root.state = pluginService.getGlobalVar(root.pluginId, "state", ({}))
        }
    }

    function statusIcon() {
        if (!state || state.phase === "error" || problemFolders > 0) return "sync_problem"
        if (state.phase !== "ready" || activeFolders > 0) return "sync"
        return "sync_alt"
    }

    function statusText() {
        if (!state || !state.phase) return "Syncthing"
        if (state.phase === "error") return "Syncthing unavailable"
        if (state.phase !== "ready") return "Syncthing loading"
        if (problemFolders > 0) return problemFolders + " problem" + (problemFolders === 1 ? "" : "s")
        var rate = Number(state.downloadBytesPerSec || 0)
        if (rate >= 1024) return "↓ " + PanelModel.formatRate(rate)
        if (activeFolders > 0) return activeFolders + " syncing"
        return String(folderRows.length)
    }

    function stateColor(folder) {
        if (folder.problem) return Theme.error
        if (folder.syncing || folder.scanning) return Theme.primary
        if (folder.paused) return Theme.surfaceVariantText
        return Theme.success
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon { name: root.statusIcon(); color: root.problemFolders ? Theme.error : Theme.primary; size: Theme.iconSize - 5 }
            StyledText { text: root.statusText(); color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium }
        }
    }

    verticalBarPill: Component {
        DankIcon { name: root.statusIcon(); color: root.problemFolders ? Theme.error : Theme.primary; size: Theme.iconSize - 4 }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "SyncShell"
            detailsText: root.state && root.state.phase === "ready"
                ? String(root.state.connectedDeviceCount || 0) + " of "
                    + String(root.state.deviceCount || 0) + " devices connected"
                : (root.state.lastError || "Discovering Syncthing")
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - popout.detailsHeight

                Column {
                    id: summary
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: Theme.spacingS

                    StyledRect {
                        width: parent.width
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        Row {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingL

                            Column {
                                width: (parent.width - parent.spacing * 2) / 3
                                spacing: 2
                                StyledText { text: String(root.folderRows.length); color: Theme.surfaceText; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Bold }
                                StyledText { text: "FOLDERS"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                            }
                            Column {
                                width: (parent.width - parent.spacing * 2) / 3
                                spacing: 2
                                StyledText { text: PanelModel.formatBytes(root.indexedBytes); color: Theme.surfaceText; font.pixelSize: Theme.fontSizeLarge; font.weight: Font.Bold }
                                StyledText { text: "INDEXED"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                            }
                            Column {
                                width: (parent.width - parent.spacing * 2) / 3
                                spacing: 2
                                StyledText {
                                    text: Number(root.state.downloadBytesPerSec || 0) >= 1
                                        ? "↓ " + PanelModel.formatRate(root.state.downloadBytesPerSec)
                                        : (Number(root.state.uploadBytesPerSec || 0) >= 1
                                            ? "↑ " + PanelModel.formatRate(root.state.uploadBytesPerSec) : "Idle")
                                    color: root.activeFolders > 0 ? Theme.primary : Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Bold
                                }
                                StyledText {
                                    text: Number(root.state.downloadBytesPerSec || 0) >= 1
                                        && Number(root.state.uploadBytesPerSec || 0) >= 1
                                        ? "↑ " + PanelModel.formatRate(root.state.uploadBytesPerSec) : "TRANSFER"
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }
                    }
                }

                DankFlickable {
                    id: folderList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: summary.bottom
                    anchors.topMargin: Theme.spacingS
                    anchors.bottom: footer.top
                    anchors.bottomMargin: Theme.spacingS
                    contentWidth: width
                    contentHeight: folderColumn.implicitHeight
                    clip: true

                    Column {
                        id: folderColumn
                        width: folderList.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.folderRows
                            StyledRect {
                                id: card
                                required property var modelData
                                width: parent.width
                                height: modelData.activity ? 94 : 76
                                radius: Theme.cornerRadius
                                color: folderMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: 3

                                    Row {
                                        width: parent.width
                                        spacing: Theme.spacingS
                                        DankIcon {
                                            name: modelData.problem ? "folder_off" : "folder"
                                            color: root.stateColor(modelData)
                                            size: Theme.iconSize - 3
                                        }
                                        StyledText {
                                            width: parent.width - statusLabel.width - Theme.iconSize - parent.spacing * 2
                                            text: modelData.label
                                            elide: Text.ElideRight
                                            color: Theme.surfaceText
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Font.Medium
                                        }
                                        StyledText {
                                            id: statusLabel
                                            text: PanelModel.folderState(modelData)
                                            color: root.stateColor(modelData)
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                    }
                                    StyledText {
                                        width: parent.width
                                        text: PanelModel.folderMeta(modelData)
                                        elide: Text.ElideRight
                                        color: modelData.problem ? Theme.error : Theme.surfaceVariantText
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                    StyledText {
                                        visible: modelData.activity !== ""
                                        width: parent.width
                                        text: "Receiving " + String(modelData.activity).split(/[\\/]/).pop()
                                        elide: Text.ElideMiddle
                                        color: Theme.primary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                    Rectangle {
                                        visible: modelData.syncing
                                        width: parent.width
                                        height: 3
                                        radius: 2
                                        color: Theme.withAlpha(Theme.primary, 0.2)
                                        Rectangle {
                                            width: parent.width * modelData.progress
                                            height: parent.height
                                            radius: parent.radius
                                            color: Theme.primary
                                        }
                                    }
                                }
                                MouseArea {
                                    id: folderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached([
                                        "dms", "ipc", "call", "syncshell", "openFolder",
                                        String(modelData.position)
                                    ])
                                }
                            }
                        }
                    }
                }

                Row {
                    id: footer
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: Theme.spacingS

                    DankButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Refresh"
                        iconName: "refresh"
                        onClicked: Quickshell.execDetached(["dms", "ipc", "call", "syncshell", "refresh"])
                    }
                    DankButton {
                        width: (parent.width - parent.spacing) / 2
                        text: "Open Web UI"
                        iconName: "open_in_new"
                        onClicked: Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8384"])
                    }
                }
            }
        }
    }

    popoutWidth: 480
    popoutHeight: 640
}
