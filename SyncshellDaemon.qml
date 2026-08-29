import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import "core"

PluginComponent {
    id: root

    property string phase: "discovering"
    property string lastError: ""
    property string apiKey: ""
    property string executable: String(pluginData.syncthingExecutable || "syncthing")
    property string baseUrl: String(pluginData.webUiUrl || "http://127.0.0.1:8384")
    property int refreshIntervalSec: Math.max(15, Number(pluginData.refreshIntervalSec || 60))
    property int generation: 0
    property var requests: []
    property var folders: []
    property var folderStatuses: ({})
    property var devices: []
    property var connections: ({})
    property string localDeviceId: ""
    property string activity: ""
    property string keyOutput: ""

    readonly property bool online: phase === "ready"
    readonly property int connectedDeviceCount: {
        var count = localDeviceId ? 1 : 0
        var values = connections && connections.connections ? connections.connections : ({})
        var ids = Object.keys(values)
        for (var i = 0; i < ids.length; i++) if (values[ids[i]].connected === true) count++
        return count
    }

    ApiClient {
        id: api
        baseUrl: root.baseUrl
        apiKey: root.apiKey
    }

    function publicState() {
        return {
            phase: phase,
            lastError: lastError,
            folders: folders,
            folderStatuses: folderStatuses,
            deviceCount: devices.length,
            connectedDeviceCount: connectedDeviceCount,
            localDeviceId: localDeviceId,
            activity: activity
        }
    }

    function publish() {
        if (pluginService && pluginService.setGlobalVar)
            pluginService.setGlobalVar(pluginId, "state", publicState())
    }

    function track(request) {
        requests.push(request)
        return request
    }

    function request(name, options, success, failure) {
        var current = generation
        return track(api.request(name, options, function(data) {
            if (current !== root.generation) return
            success(data)
        }, function(error) {
            if (current !== root.generation) return
            if (failure) failure(error)
        }))
    }

    function discover() {
        if (keyProcess.running) return
        generation++
        phase = "discovering"
        lastError = ""
        keyOutput = ""
        publish()
        keyProcess.command = [executable, "cli", "config", "gui", "dump-json"]
        keyProcess.running = true
    }

    function refresh() {
        if (!apiKey) { discover(); return }
        generation++
        phase = "loading"
        lastError = ""
        folderStatuses = ({})
        publish()
        var pending = 4
        function finished() {
            pending--
            if (pending === 0) { root.phase = "ready"; root.publish() }
        }
        function failed(error) {
            root.phase = "error"
            root.lastError = error && error.message ? String(error.message) : "Connection failed"
            root.publish()
        }
        request("getSystemStatus", {}, function(data) {
            root.localDeviceId = String((data || {}).myID || ""); finished()
        }, failed)
        request("getConnections", {}, function(data) {
            root.connections = data || ({}); finished()
        }, failed)
        request("getDevices", {}, function(data) {
            root.devices = data instanceof Array ? data : []; finished()
        }, failed)
        request("getFolders", {}, function(data) {
            root.folders = data instanceof Array ? data : []
            for (var i = 0; i < root.folders.length; i++) root.fetchFolder(root.folders[i].id)
            finished()
        }, failed)
    }

    function fetchFolder(folderId) {
        request("getFolderStatus", { query: { folder: folderId } }, function(data) {
            var next = Object.assign({}, root.folderStatuses)
            next[String(folderId)] = data || ({})
            root.folderStatuses = next
            root.publish()
        }, function() {})
    }

    Process {
        id: keyProcess
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.keyOutput = text
        }
        onExited: function(exitCode) {
            var config = null
            try { config = JSON.parse(root.keyOutput) } catch (error) {}
            var key = config ? String(config.apiKey || "").trim() : ""
            root.keyOutput = ""
            if (exitCode === 0 && key) {
                root.apiKey = key
                root.baseUrl = (config.useTLS === true ? "https" : "http") + "://127.0.0.1:8384"
                root.refresh()
            } else {
                root.phase = "error"
                root.lastError = "Could not discover the local Syncthing API"
                root.publish()
            }
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "syncshell"
        function refresh(): void { root.refresh() }
        function status(): string {
            return "phase=" + root.phase + " folders=" + root.folders.length
                + " devices=" + root.connectedDeviceCount + "/" + root.devices.length
                + (root.lastError ? " error=" + root.lastError : "")
        }
    }

    Component.onDestruction: {
        generation++
        apiKey = ""
        keyOutput = ""
    }
}
