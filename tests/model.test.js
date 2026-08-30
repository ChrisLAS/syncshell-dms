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
  localDeviceId: "LOCAL",
  folders: [{
    id: "docs",
    label: "Documents",
    path: "~/Documents",
    paused: false,
    devices: [{ deviceID: "LOCAL" }, { deviceID: "REMOTE" }]
  }],
  folderStatuses: {
    docs: {
      state: "syncing",
      globalFiles: 42,
      globalBytes: 1073741824,
      inSyncBytes: 805306368,
      needBytes: 268435456,
      needTotalItems: 2
    }
  },
  folderActivity: { docs: "reports/annual.pdf" }
}, "/home/test")

if (rows.length !== 1 || rows[0].resolvedPath !== "/home/test/Documents")
  throw new Error("folder projection failed")
if (model.folderMeta(rows[0]) !== "2 items remaining · 256 MiB")
  throw new Error("folder summary failed")
if (rows[0].progress !== 0.75 || rows[0].activity !== "reports/annual.pdf")
  throw new Error("folder progress failed")
if (model.formatBytes(rows[0].globalBytes) !== "1.0 GiB")
  throw new Error("byte formatting failed")
if (model.folderState(rows[0]) !== "SYNCING")
  throw new Error("folder state failed")

const publicRows = model.publicFolderRows({
  localDeviceId: "LOCAL",
  folders: [{
    id: "private-id",
    label: "Documents",
    path: "/home/test/Documents",
    devices: [{ deviceID: "LOCAL" }, { deviceID: "PRIVATE-REMOTE-ID" }]
  }],
  folderStatuses: {
    "private-id": {
      state: "error",
      error: "/home/test/Documents/private-file failed",
      globalFiles: 42
    }
  },
  folderActivity: {
    "private-id": "reports/private-file.pdf"
  }
}, "/home/test")
if (publicRows.length !== 1 || publicRows[0].position !== 0)
  throw new Error("public folder projection failed")
if ("id" in publicRows[0] || "path" in publicRows[0] || "resolvedPath" in publicRows[0])
  throw new Error("public folder projection exposed an identifier or path")
if (JSON.stringify(publicRows).indexOf("PRIVATE-REMOTE-ID") !== -1
    || JSON.stringify(publicRows).indexOf("/home/test") !== -1
    || publicRows[0].activity !== "private-file.pdf")
  throw new Error("public folder projection exposed private metadata")

const rate = model.sampleRate(
  { at: "2026-08-30T08:00:00Z", inBytesTotal: 1000, outBytesTotal: 500 },
  { at: "2026-08-30T08:00:02Z", inBytesTotal: 5000, outBytesTotal: 2500 }
)
if (rate.downloadBytesPerSec !== 2000 || rate.uploadBytesPerSec !== 1000)
  throw new Error("rate sampling failed")
const resetRate = model.sampleRate(
  { at: "2026-08-30T08:00:02Z", inBytesTotal: 5000, outBytesTotal: 2500 },
  { at: "2026-08-30T08:00:04Z", inBytesTotal: 10, outBytesTotal: 10 }
)
if (resetRate.downloadBytesPerSec !== 0 || resetRate.uploadBytesPerSec !== 0)
  throw new Error("rate reset failed")

console.log("model tests passed")
