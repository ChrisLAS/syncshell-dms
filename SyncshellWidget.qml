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
    property var folderRows: PanelModel.buildFolderRows(state, Quickshell.env("HOME"))

    Connections {
        target: pluginService
        function onGlobalVarChanged(changedPluginId, name) {
            if (changedPluginId === root.pluginId && name === "state")
                root.state = pluginService.getGlobalVar(root.pluginId, "state", ({}))
        }
    }

    function statusIcon() {
        if (!state || state.phase === "error") return "sync_problem"
        if (state.phase !== "ready") return "sync"
        for (var i = 0; i < folderRows.length; i++) {
            if (folderRows[i].problem) return "sync_problem"
            if (folderRows[i].syncing || folderRows[i].scanning) return "sync"
        }
        return "sync_alt"
    }

    function statusText() {
        if (!state || !state.phase) return "Syncthing"
        if (state.phase === "error") return "Syncthing unavailable"
        if (state.phase !== "ready") return "Syncthing loading"
        return folderRows.length + " folders"
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon { name: root.statusIcon(); color: Theme.primary; size: Theme.iconSize - 5 }
            StyledText { text: root.statusText(); color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium }
        }
    }

    verticalBarPill: Component {
        DankIcon { name: root.statusIcon(); color: Theme.primary; size: Theme.iconSize - 4 }
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

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.folderRows
                    Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 54
                        radius: Theme.cornerRadius
                        color: folderMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.spacingM
                            spacing: 2
                            StyledText {
                                text: modelData.label
                                color: modelData.problem ? Theme.error : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                            }
                            StyledText {
                                text: PanelModel.folderMeta(modelData)
                                color: Theme.surfaceTextMedium
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }
                        MouseArea {
                            id: folderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (modelData.resolvedPath)
                                Quickshell.execDetached(["xdg-open", modelData.resolvedPath])
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: Theme.cornerRadius
                    color: webMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    StyledText { anchors.centerIn: parent; text: "Open Syncthing Web UI"; color: Theme.primary }
                    MouseArea {
                        id: webMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", "http://127.0.0.1:8384"])
                    }
                }
            }
        }
    }

    popoutWidth: 430
    popoutHeight: Math.min(620, 145 + folderRows.length * 62)
}
