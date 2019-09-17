local template = {}

template.indentation_depth = 0
template.indent_spaces = ".."

local function indent()
    local indents = {}
    for i=1, template.indentation_depth do
        table.insert(indents, template.indent_spaces)
    end
    return table.concat(indents, "")
end

local function inc_indent()
    template.indentation_depth = template.indentation_depth + 1
    return ""
end

local function dec_indent()
    template.indentation_depth = template.indentation_depth - 1
    return ""
end


function template.escape(data)
  return tostring(data or ''):gsub("[\">/<'&]", {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
    ["/"] = "&#47;"
  })
end

function template.print(data, args, callback)
  local callback = callback or print
  local function exec(data)
    if type(data) == "function" then
      local args = args or {}
      args.inc_indent = inc_indent
      args.dec_indent = dec_indent
      args.indent = indent
      setmetatable(args, { __index = _G })
      setfenv(data, args)
      data(exec)
    else
      callback(tostring(data or ''))
    end
  end
  exec(data)
end

function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

function template.parse(data, minify)
  local new_data = {}
  for line in magiclines(data) do
    local new_line = 
      line:
        gsub("[][]=[][]", ']=]_"%1"_[=[\n'):
        gsub("<%%=", "]=]_("):
        gsub("<%%", "]=]__("):
        gsub("%%>", ")_[=[\n"):
        gsub("<%?", "]=] "):
        gsub("%?>", " _[=[\n"): 
        gsub("%%%->", "]=]__(inc_indent())_[=[\n"):
        gsub("%%<%-", "]=]__(dec_indent())_[=[\n"):
--        gsub("^[ ]*", "]=]__(indent())_[=[\n")
        gsub("^[ ]*(%S+)", "]=]__(indent())_[=[\n%1")
    table.insert(new_data, new_line)
  end
  local replaced_data = table.concat(new_data, "\n")

  local str = 
    "return function(_)" .. 
      "function __(...)" ..
        "_(require('template').escape(...))" ..
      "end " ..
      "_[=[" ..
      replaced_data
--      data:
--        gsub("[][]=[][]", ']=]_"%1"_[=['):
--        gsub("<%%=", "]=]_("):
--        gsub("<%%", "]=]__("):
--        gsub("%%>", ")_[=["):
--        gsub("<%?", "]=] "):
--        gsub("%?>", " _[=["): 
--        gsub("[ ]*%%%->[ ]*\n", "]=]__(inc_indent())_[=[\n"):
--        gsub("[ ]*%%<%-[ ]*\n", "]=]__(dec_indent())_[=[\n"):
--        gsub("^[ ]*", "]=]__(indent())_[=["):
--        gsub("\n[ ]*(%S+)", "\n]=]__(indent())_[=[%1")
        ..
      "]=] " ..
    "end"
  if minify then
    str = str:
      gsub("^[ %s]*", "]=]__(indent())_[=["):
      gsub("[ %s]*$", ""):
      gsub("%s+", " ")
  end
  print("----------------------------")
  print(str)
  print("----------------------------")
  return str
end

function template.compile(...)
  return loadstring(template.parse(...))()
end

return template
