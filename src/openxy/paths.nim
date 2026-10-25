## Repository layout resolved from this module's location.
##
## The same module works from a normal checkout (`openxy/open-xy`) and from
## an Atlas dependency (`deps/openxy/open-xy`); no environment variables are
## involved.

import std/strutils

const
  thisFile = currentSourcePath()
  separator = if thisFile.contains('\\'): '\\' else: '/'
  srcMarker = separator & "src" & separator
  srcIndex = thisFile.rfind(srcMarker)
  openxyRoot* = thisFile[0 ..< srcIndex]
  sdkRoot* = openxyRoot & separator & "open-xy"
  scriptsRoot* = openxyRoot & separator & "scripts"
  templatesRoot* = openxyRoot & separator & "templates"
