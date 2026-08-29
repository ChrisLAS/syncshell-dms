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
    rows.push({
      id: id,
      label: String(folder.label || "") || pathLabel(resolveFolderPath(folder.path, homePath)) || id,
      path: String(folder.path || ""),
      resolvedPath: resolveFolderPath(folder.path, homePath),
      problem: stateName === "error" || !!status.error || errors > 0,
      syncing: needItems > 0 || stateName.indexOf("sync") === 0,
      scanning: stateName.indexOf("scan") === 0,
      paused: folder.paused === true,
      needItems: needItems,
      globalFiles: Number(status.globalFiles || 0)
    })
  }
  return rows
}

function formatCount(value) {
  var count = Math.max(0, Number(value || 0))
  if (count >= 1000000) return (count / 1000000).toFixed(1) + "m"
  if (count >= 1000) return (count / 1000).toFixed(count >= 10000 ? 0 : 1) + "k"
  return String(Math.round(count))
}

function folderMeta(folder) {
  if (folder.problem) return "Needs attention"
  if (folder.paused) return "Paused"
  if (folder.scanning) return "Scanning"
  if (folder.syncing) return formatCount(folder.needItems) + " items remaining"
  return formatCount(folder.globalFiles) + " files"
}
