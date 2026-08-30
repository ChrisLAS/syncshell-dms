.pragma library

function resolveFolderPath(value, homePath) {
  var path = String(value || "")
  if (path === "~") return homePath
  if (path.indexOf("~/") === 0) return homePath + path.slice(1)
  if (path.charAt(0) === "/" || !homePath) return path
  return homePath + "/" + path
}

function pathLabel(path) {
  var value = String(path || "").replace(/\/+$/, "")
  if (String(path || "").charAt(0) === "/" && value === "") return "/"
  var parts = value.split("/")
  return parts.length && parts[parts.length - 1] ? parts[parts.length - 1] : "Folder"
}

function buildFolderRows(state, homePath) {
  var rows = []
  var folders = state && state.folders ? state.folders : []
  var statuses = state && state.folderStatuses ? state.folderStatuses : ({})
  for (var i = 0; i < folders.length; i++) {
    var folder = folders[i] || ({})
    var id = String(folder.id || "")
    var status = statuses[id] || ({})
    var stateName = String(status.state || "unknown")
    var errors = Number(status.errors || 0) + Number(status.pullErrors || 0)
    var needItems = Number(status.needTotalItems || 0)
    var globalBytes = Number(status.globalBytes || 0)
    var needBytes = Number(status.needBytes || 0)
    var inSyncBytes = Number(status.inSyncBytes || Math.max(0, globalBytes - needBytes))
    var folderDevices = folder.devices || []
    var sharedDeviceCount = 0
    for (var j = 0; j < folderDevices.length; j++) {
      var deviceId = String((folderDevices[j] || {}).deviceID || "")
      if (deviceId && deviceId !== String((state || {}).localDeviceId || "")) sharedDeviceCount++
    }
    rows.push({
      id: id,
      label: String(folder.label || "") || pathLabel(resolveFolderPath(folder.path, homePath)) || id,
      path: String(folder.path || ""),
      resolvedPath: resolveFolderPath(folder.path, homePath),
      problem: stateName === "error" || !!status.error || errors > 0,
      syncing: needItems > 0 || stateName.indexOf("sync") === 0,
      scanning: stateName.indexOf("scan") === 0,
      paused: folder.paused === true,
      state: stateName,
      error: String(status.error || ""),
      needItems: needItems,
      needBytes: needBytes,
      globalBytes: globalBytes,
      localBytes: Number(status.localBytes || 0),
      inSyncBytes: inSyncBytes,
      globalFiles: Number(status.globalFiles || 0),
      globalDirectories: Number(status.globalDirectories || 0),
      sharedDeviceCount: sharedDeviceCount,
      activity: String(((state || {}).folderActivity || ({}))[id] || ""),
      progress: globalBytes > 0
        ? Math.max(0, Math.min(1, inSyncBytes / globalBytes)) : 1
    })
  }
  return rows
}

function publicFolderRows(state, homePath) {
  var rows = buildFolderRows(state, homePath)
  var safeRows = []
  for (var i = 0; i < rows.length; i++) {
    var folder = rows[i]
    var activityParts = String(folder.activity || "").split(/[\\/]/)
    safeRows.push({
      position: i,
      label: folder.label,
      problem: folder.problem,
      syncing: folder.syncing,
      scanning: folder.scanning,
      paused: folder.paused,
      state: folder.state,
      error: folder.problem ? "Needs attention" : "",
      needItems: folder.needItems,
      needBytes: folder.needBytes,
      globalBytes: folder.globalBytes,
      localBytes: folder.localBytes,
      inSyncBytes: folder.inSyncBytes,
      globalFiles: folder.globalFiles,
      globalDirectories: folder.globalDirectories,
      sharedDeviceCount: folder.sharedDeviceCount,
      activity: activityParts.length ? activityParts[activityParts.length - 1] : "",
      progress: folder.progress
    })
  }
  return safeRows
}

function total(rows, key) {
  var value = 0
  for (var i = 0; i < rows.length; i++) value += Number(rows[i][key] || 0)
  return value
}

function formatCount(value) {
  var count = Math.max(0, Number(value || 0))
  if (count >= 1000000) return (count / 1000000).toFixed(1) + "m"
  if (count >= 1000) return (count / 1000).toFixed(count >= 10000 ? 0 : 1) + "k"
  return String(Math.round(count))
}

function formatBytes(value) {
  var bytes = Math.max(0, Number(value || 0))
  var units = ["B", "KiB", "MiB", "GiB", "TiB"]
  var unit = 0
  while (bytes >= 1024 && unit < units.length - 1) {
    bytes /= 1024
    unit++
  }
  return (unit === 0 ? String(Math.round(bytes))
    : bytes.toFixed(bytes >= 10 ? 0 : 1)) + " " + units[unit]
}

function formatRate(value) {
  return formatBytes(value) + "/s"
}

function sampleRate(previous, current) {
  var before = previous || ({})
  var after = current || ({})
  var beforeAt = Date.parse(String(before.at || ""))
  var afterAt = Date.parse(String(after.at || ""))
  var seconds = (afterAt - beforeAt) / 1000
  var beforeIn = Number(before.inBytesTotal || 0)
  var afterIn = Number(after.inBytesTotal || 0)
  var beforeOut = Number(before.outBytesTotal || 0)
  var afterOut = Number(after.outBytesTotal || 0)
  if (!(seconds > 0) || afterIn < beforeIn || afterOut < beforeOut)
    return { downloadBytesPerSec: 0, uploadBytesPerSec: 0 }
  return {
    downloadBytesPerSec: (afterIn - beforeIn) / seconds,
    uploadBytesPerSec: (afterOut - beforeOut) / seconds
  }
}

function folderState(folder) {
  if (folder.problem) return "ERROR"
  if (folder.paused) return "PAUSED"
  if (folder.scanning) return "SCANNING"
  if (folder.syncing) return "SYNCING"
  return "SYNCED"
}

function folderMeta(folder) {
  if (folder.problem) return folder.error || "Needs attention"
  if (folder.paused) return "Paused"
  if (folder.scanning) return "Scanning"
  if (folder.syncing) {
    var remaining = formatCount(folder.needItems) + " item"
      + (folder.needItems === 1 ? "" : "s") + " remaining"
    return folder.needBytes > 0 ? remaining + " · " + formatBytes(folder.needBytes) : remaining
  }
  var sharing = folder.sharedDeviceCount === 0 ? " · local only" : ""
  return formatCount(folder.globalFiles) + " files · " + formatBytes(folder.globalBytes) + sharing
}
