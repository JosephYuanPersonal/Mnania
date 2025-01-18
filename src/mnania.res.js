// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Path from "path";
import * as Js_exn from "rescript/lib/es6/js_exn.js";
import * as Jquery from "jquery";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Js_array from "rescript/lib/es6/js_array.js";
import * as Js_string from "rescript/lib/es6/js_string.js";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Belt_Option from "rescript/lib/es6/belt_Option.js";
import * as Belt_SetString from "rescript/lib/es6/belt_SetString.js";

function isSystemPath(path) {
  var systemPaths = [
    "/dev",
    "/.vfs_config",
    "/dev/memory"
  ];
  return Js_array.includes(path, systemPaths);
}

function resolveSymlink(fs, path) {
  var _current = path;
  while(true) {
    var current = _current;
    var target = Js_dict.get(fs.symlinks, current);
    if (target === undefined) {
      return current;
    }
    if (Belt_SetString.has(undefined, target)) {
      throw Js_exn.raiseError("Circular symbolic link");
    }
    Belt_SetString.add(undefined, target);
    _current = target;
    continue ;
  };
}

function normalizePath(fs, path) {
  if (Js_string.startsWith(path, "/")) {
    return path;
  } else {
    return Path.join(fs.currentPath, path);
  }
}

function checkSystemPath(path) {
  if (!isSystemPath(path)) {
    return ;
  }
  throw Js_exn.raiseError("Insufficient permissions: system paths cannot be modified");
}

function writeFile(fs, path, content) {
  checkSystemPath(path);
  var fullPath = normalizePath(fs, path);
  fs.files[resolveSymlink(fs, fullPath)] = content;
}

function touch(fs, path) {
  checkSystemPath(path);
  var fullPath = normalizePath(fs, path);
  var resolvedPath = resolveSymlink(fs, fullPath);
  if (Belt_Option.isNone(Js_dict.get(fs.files, resolvedPath))) {
    return writeFile(fs, resolvedPath, "");
  }
  
}

function mkdir(fs, path) {
  checkSystemPath(path);
  var fullPath = normalizePath(fs, path);
  var resolvedPath = resolveSymlink(fs, fullPath);
  if (Belt_Option.isNone(Js_dict.get(fs.dirs, resolvedPath))) {
    fs.dirs[resolvedPath] = [];
    return ;
  }
  
}

function readdir(fs, path) {
  var resolvedPath = resolveSymlink(fs, path);
  return Belt_Option.getWithDefault(Js_dict.get(fs.dirs, resolvedPath), []);
}

function stat(fs, path) {
  var resolvedPath = resolveSymlink(fs, path);
  return {
          isDirectory: (function () {
              return Belt_Option.isSome(Js_dict.get(fs.dirs, resolvedPath));
            }),
          isFile: (function () {
              return Belt_Option.isSome(Js_dict.get(fs.files, resolvedPath));
            }),
          isSymbolicLink: (function () {
              return Belt_Option.isSome(Js_dict.get(fs.symlinks, path));
            }),
          isExecutable: Belt_Option.isSome(Js_dict.get(fs.execlinks, path)) ? (function () {
                return true;
              }) : undefined,
          isSystem: isSystemPath(path)
        };
}

function makeMnaniaFS() {
  var fs_files = {};
  var fs_dirs = {};
  var fs_symlinks = {};
  var fs_execlinks = {};
  var fs_systemPaths = [
    "/dev",
    "/.vfs_config",
    "/dev/memory"
  ];
  var fs = {
    files: fs_files,
    dirs: fs_dirs,
    symlinks: fs_symlinks,
    execlinks: fs_execlinks,
    currentPath: "/dev/memory",
    systemPaths: fs_systemPaths
  };
  fs_dirs["/dev"] = ["memory"];
  fs_dirs["/dev/memory"] = [];
  var config = {};
  config["readOnlyPaths"] = [
    "/dev",
    "/.vfs_config",
    "/dev/memory"
  ];
  config["defaultPermissions"] = "rw";
  config["defaultFS"] = "/dev/memory";
  fs_files["/.vfs_config"] = JSON.stringify(config);
  return fs;
}

function makeWindowManager() {
  return {
          windows: [],
          topZIndex: 1000
        };
}

function focusWindow(wm, $$window) {
  wm.topZIndex = wm.topZIndex + 1 | 0;
  $$window.element.css("z-index", String(wm.topZIndex));
}

function executeCommand(fs, cmd) {
  var args = Js_string.split(" ", cmd);
  var match = Belt_Array.get(args, 0);
  var match$1 = Belt_Array.get(args, 1);
  if (match !== undefined) {
    switch (match) {
      case "ls" :
          return readdir(fs, Belt_Option.getWithDefault(match$1, fs.currentPath));
      case "mkdir" :
          if (match$1 !== undefined) {
            mkdir(fs, match$1);
            return [];
          }
          throw Js_exn.raiseError("mkdir: missing directory name");
      case "touch" :
          if (match$1 !== undefined) {
            touch(fs, match$1);
            return [];
          }
          throw Js_exn.raiseError("touch: missing filename");
      default:
        throw Js_exn.raiseError("Unknown command: " + match);
    }
  } else {
    throw Js_exn.raiseError("Empty command");
  }
}

var mnaniaInstance = {
  contents: undefined
};

var mnania = {
  start: (function (container) {
      var elem = Jquery.jQuery(container);
      elem.addClass("mnania-desktop");
      var fs = makeMnaniaFS();
      var wm = {
        windows: [],
        topZIndex: 1000
      };
      var instance = {
        fs: fs,
        wm: wm
      };
      mnaniaInstance.contents = instance;
      return instance;
    }),
  executeCommand: executeCommand,
  createWindow: (function (container, id) {
      var elem = Jquery.jQuery(container);
      elem.addClass("mnania-window");
      var $$window = {
        id: id,
        element: elem,
        zIndex: 1000
      };
      elem.on("mousedown", (function () {
              var instance = mnaniaInstance.contents;
              if (instance !== undefined) {
                return focusWindow(instance.wm, $$window);
              }
              throw Js_exn.raiseError("Mnania not initialized");
            }));
      return $$window;
    })
};

export {
  isSystemPath ,
  resolveSymlink ,
  normalizePath ,
  checkSystemPath ,
  writeFile ,
  touch ,
  mkdir ,
  readdir ,
  stat ,
  makeMnaniaFS ,
  makeWindowManager ,
  focusWindow ,
  executeCommand ,
  mnaniaInstance ,
  mnania ,
}
/* path Not a pure module */
