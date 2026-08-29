const fs = require("fs")
const vm = require("vm")

function load(path) {
  const source = fs.readFileSync(path, "utf8").replace(/^\.pragma library\s*/, "")
  const context = {}
  vm.createContext(context)
  vm.runInContext(source, context)
  return context
}

const model = load("models/PanelModel.js")
const rows = model.buildFolderRows({
  folders: [{ id: "docs", label: "Documents", path: "~/Documents", paused: false }],
  folderStatuses: { docs: { state: "idle", globalFiles: 42 } }
}, "/home/test")

if (rows.length !== 1 || rows[0].resolvedPath !== "/home/test/Documents")
  throw new Error("folder projection failed")
if (model.folderMeta(rows[0]) !== "42 files")
  throw new Error("folder summary failed")

console.log("model tests passed")
