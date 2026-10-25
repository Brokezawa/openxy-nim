## Filesystem primitives that exist in both native and NimScript builds.

when defined(nimscript):
  proc ensureDir*(path: string) =
    if not dirExists(path):
      mkdir(path)

  proc copyFileCompat*(source, destination: string) =
    cpFile(source, destination)

  proc copyDirCompat*(source, destination: string) =
    cpDir(source, destination)

  proc removeDirCompat*(path: string) =
    if dirExists(path):
      rmDir(path)
else:
  import std/os

  proc ensureDir*(path: string) =
    createDir(path)

  proc copyFileCompat*(source, destination: string) =
    copyFile(source, destination)

  proc copyDirCompat*(source, destination: string) =
    copyDir(source, destination)

  proc removeDirCompat*(path: string) =
    if dirExists(path):
      removeDir(path)
