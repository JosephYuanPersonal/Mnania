// Mnania is a webos launcher like explorer.exe (only about it's desktop function, try running "taskkill /im explorer.exe /f", NEVER RUN IT IN WIN+R EXCEPT YOU HAVE A TERMINAL WINDOW OPENED, BECAUSE THE WIN+R WILL NOT WORK IF KILLING THE EXPLORER.EXE, AND YOU CAN'T RUN IT IN TERMINAL WINDOW, BECAUSE THE TERMINAL WINDOW WILL NOT WORK IF KILLING THE EXPLORER.EXE) or gnome-desktop
// And both a framework for handling a file system like a kernel
// It is for a brand new operating system named by Renu-Lo
// The name of "Mnania" is a name "nine" in my own constructed language named "Nari-Syri"
// You can run the function "Mnania.start(Node)" to start the desktop
// 定义类型
type rec fileSystemEntry = {
  isDirectory: unit => bool,
  isFile: unit => bool,
  isSymbolicLink: unit => bool,
  isExecutable: option<unit => bool>,
  isSystem: bool,
}

type fs = {
  files: Js.Dict.t<string>,
  dirs: Js.Dict.t<array<string>>,
  symlinks: Js.Dict.t<string>,
  execlinks: Js.Dict.t<string => string>,
  currentPath: string,
  systemPaths: array<string>,
}

// 窗口类型
type window = {
  id: string,
  element: {
    "addClass": string => unit,
    "css": (string, string) => unit,
    "on": (string, unit => unit) => unit,
  },
  zIndex: int,
}

// 窗口管理器
type windowManager = {
  mutable windows: array<window>,
  mutable topZIndex: int,
}

// Mnania 实例类型
type mnaniaInstance = {
  fs: fs,
  wm: windowManager,
}

// 外部 JS 绑定
@module("path") external joinPath: (string, string) => string = "join"
@module("jquery") external jQuery: string => {
  "addClass": string => unit,
  "css": (string, string) => unit,
  "on": (string, unit => unit) => unit,
} = "jQuery"
@module external require: string => 'a = "require"

// 系统路径检查
let isSystemPath = path => {
  let systemPaths = ["/dev", "/.vfs_config", "/dev/memory"]
  Js.Array.includes(path, systemPaths)
}

// 文件系统操作
let resolveSymlink = (fs, path) => {
  let visited = Belt.Set.String.empty
  let rec loop = current =>
    switch Js.Dict.get(fs.symlinks, current) {
    | None => current
    | Some(target) if Belt.Set.String.has(visited, target) => raise(Js.Exn.raiseError("Circular symbolic link"))
    | Some(target) => {
        let _ = Belt.Set.String.add(visited, target)
        loop(target)
      }
    }
  loop(path)
}

let normalizePath = (~fs, ~path) =>
  Js.String.startsWith(path, "/") ? path : joinPath(fs.currentPath, path)

let checkSystemPath = path =>
  if isSystemPath(path) {
    raise(Js.Exn.raiseError("Insufficient permissions: system paths cannot be modified"))
  }

// 获取父目录路径
let getParentDir = path => {
  let parts = Js.String.split("/", path)
  let parentParts = Belt.Array.slice(parts, ~offset=0, ~len=Belt.Array.length(parts) - 1)
  Js.Array.joinWith("/", parentParts)
}

// 获取文件名
let getFileName = path => {
  let parts = Js.String.split("/", path)
  Belt.Array.getExn(parts, Belt.Array.length(parts) - 1)
}

let rec writeFile = (~fs, ~path, ~content) => {
  checkSystemPath(path)
  let fullPath = normalizePath(~fs, ~path)
  let resolvedPath = resolveSymlink(fs, fullPath)
  Js.Dict.set(fs.files, resolvedPath, content)
  // 更新目录条目
  let parentDir = getParentDir(resolvedPath)
  let fileName = getFileName(resolvedPath)
  
  switch Js.Dict.get(fs.dirs, parentDir) {
  | Some(entries) =>
    if !Js.Array.includes(fileName, entries) {
      Js.Dict.set(fs.dirs, parentDir, Belt.Array.concat(entries, [fileName]))
    }
  | None => 
    if parentDir !== "" {
      mkdir(~fs, ~path=parentDir)
      Js.Dict.set(fs.dirs, parentDir, [fileName])
    }
  }
}

and touch = (~fs, ~path) => {
  checkSystemPath(path)
  let fullPath = normalizePath(~fs, ~path)
  let resolvedPath = resolveSymlink(fs, fullPath)
  if Js.Dict.get(fs.files, resolvedPath)->Belt.Option.isNone {
    writeFile(~fs, ~path=resolvedPath, ~content="")
  }
}

and mkdir = (~fs, ~path) => {
  checkSystemPath(path)
  let fullPath = normalizePath(~fs, ~path)
  let resolvedPath = resolveSymlink(fs, fullPath)
  if Js.Dict.get(fs.dirs, resolvedPath)->Belt.Option.isNone {
    Js.Dict.set(fs.dirs, resolvedPath, [])
    // 更新目录条目
    let parentDir = getParentDir(resolvedPath)
    let dirName = getFileName(resolvedPath)
    
    switch Js.Dict.get(fs.dirs, parentDir) {
    | Some(entries) =>
      if !Js.Array.includes(dirName, entries) {
        Js.Dict.set(fs.dirs, parentDir, Belt.Array.concat(entries, [dirName]))
      }
    | None => 
      if parentDir !== "" {
        mkdir(~fs, ~path=parentDir)
        Js.Dict.set(fs.dirs, parentDir, [dirName])
      }
    }
  }
}

let readdir = (~fs, ~path) => {
  let resolvedPath = resolveSymlink(fs, path)
  Js.Dict.get(fs.dirs, resolvedPath)->Belt.Option.getWithDefault([])
}

let stat = (~fs, ~path) => {
  let resolvedPath = resolveSymlink(fs, path)
  {
    isDirectory: () => Js.Dict.get(fs.dirs, resolvedPath)->Belt.Option.isSome,
    isFile: () => Js.Dict.get(fs.files, resolvedPath)->Belt.Option.isSome,
    isSymbolicLink: () => Js.Dict.get(fs.symlinks, path)->Belt.Option.isSome,
    isExecutable: Js.Dict.get(fs.execlinks, path)->Belt.Option.isSome ? Some(() => true) : None,
    isSystem: isSystemPath(path),
  }
}

// 初始化文件系统
let makeMnaniaFS = () => {
  let fs = {
    files: Js.Dict.empty(),
    dirs: Js.Dict.empty(),
    symlinks: Js.Dict.empty(),
    execlinks: Js.Dict.empty(),
    currentPath: "/dev/memory",
    systemPaths: ["/dev", "/.vfs_config", "/dev/memory"],
  }
  
  // 初始化系统目录和文件
  Js.Dict.set(fs.dirs, "/dev", ["memory"])
  Js.Dict.set(fs.dirs, "/dev/memory", [])
  
  // 使用 Js.Json 创建配置对象
  let config = Js.Dict.empty()
  Js.Dict.set(config, "readOnlyPaths", Js.Json.stringArray(["/dev", "/.vfs_config", "/dev/memory"]))
  Js.Dict.set(config, "defaultPermissions", Js.Json.string("rw"))
  Js.Dict.set(config, "defaultFS", Js.Json.string("/dev/memory"))
  
  Js.Dict.set(fs.files, "/.vfs_config", Js.Json.stringify(Js.Json.object_(config)))
  fs
}

// 窗口管理器
let makeWindowManager = () => {
  windows: [],
  topZIndex: 1000,
}

// 窗口焦点管理
let focusWindow = (~wm: windowManager, ~window: window) => {
  wm.topZIndex = wm.topZIndex + 1
  window.element["css"]("z-index", Belt.Int.toString(wm.topZIndex))
}

// 文件操作辅助函数
let readFileAsText = (file: Js.File.t) => {
  Promise.make((resolve, reject) => {
    let reader = Js.File.reader()
    reader["onload"] = () => resolve(. reader["result"])
    reader["onerror"] = () => reject(. Js.Exn.raiseError("Failed to read file"))
    reader["readAsText"](file)
  })
}

// 下载文件
let downloadFile = (~filename: string, ~content: string) => {
  let blob = Js.Blob.make2([content], {"type": "text/plain"})
  let url = Js.URL.createObjectURL(blob)
  let a = document["createElement"]("a")
  a["href"] = url
  a["download"] = filename
  a["click"]()
  Js.URL.revokeObjectURL(url)
}

// 命令处理
let executeCommand = (~fs, ~cmd) => {
  let args = Js.String.split(" ", cmd)
  switch (Belt.Array.get(args, 0), Belt.Array.get(args, 1)) {
  | (Some("touch"), Some(path)) => {
      touch(~fs, ~path)
      []  // 返回空数组
    }
  | (Some("touch"), None) => raise(Js.Exn.raiseError("touch: missing filename"))
  | (Some("mkdir"), Some(path)) => {
      mkdir(~fs, ~path)
      []  // 返回空数组
    }
  | (Some("mkdir"), None) => raise(Js.Exn.raiseError("mkdir: missing directory name"))
  | (Some("ls"), path) => readdir(~fs, ~path=Belt.Option.getWithDefault(path, fs.currentPath))
  | (Some("upload"), Some(path)) => {
      let input = document["createElement"]("input")
      input["type"] = "file"
      input["onchange"] = async event => {
        let file = event["target"]["files"][0]
        let content = await readFileAsText(file)
        writeFile(~fs, ~path, ~content)
      }
      input["click"]()
      []
    }
  | (Some("download"), Some(path)) => {
      let resolvedPath = resolveSymlink(fs, path)
      switch Js.Dict.get(fs.files, resolvedPath) {
      | Some(content) => 
          let filename = Js.String.split("/", path)->Belt.Array.getExn(-1)
          downloadFile(~filename, ~content)
          []
      | None => raise(Js.Exn.raiseError(`File not found: ${path}`))
      }
    }
  | (Some(cmd), _) => raise(Js.Exn.raiseError(`Unknown command: ${cmd}`))
  | (None, _) => raise(Js.Exn.raiseError("Empty command"))
  }
}

// 全局实例引用
let mnaniaInstance = ref(None)

// 导出对象
let mnania = {
  "start": container => {
    let elem = jQuery(container)
    elem["addClass"]("mnania-desktop")
    let fs = makeMnaniaFS()
    let wm = makeWindowManager()
    let instance = ({fs, wm}: mnaniaInstance)
    mnaniaInstance := Some(instance)
    instance
  },
  "executeCommand": executeCommand,
  "createWindow": (~container, ~id) => {
    let elem = jQuery(container)
    elem["addClass"]("mnania-window")
    let window = {
      id,
      element: elem,
      zIndex: 1000,
    }
    elem["on"]("mousedown", _ => {
      switch mnaniaInstance.contents {
      | Some(instance) => focusWindow(~wm=instance.wm, ~window)
      | None => raise(Js.Exn.raiseError("Mnania not initialized"))
      }
    })
    window
  },
}