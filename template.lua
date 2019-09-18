local template = {}

template.indentation_depth = 0
template.indent_spaces = "  "

local indent_functions = {}
function indent_functions.indent()
    local indents = {}
    for i=1, template.indentation_depth do
        table.insert(indents, template.indent_spaces)
    end
    return table.concat(indents, "")
end

function indent_functions.inc_indent(indents)
    template.indentation_depth = template.indentation_depth + #indents
    return ""
end

function indent_functions.dec_indent(indents)
    template.indentation_depth = template.indentation_depth - #indents
    return ""
end

function template.render(data, args)
  local return_str = ""
  local function string_cat(x)
      return_str = return_str .. x
  end

  local function exec(data)
    if type(data) == "function" then
      local args = args or {}
      setmetatable(args, { __index = _G })
      setfenv(data, args)
      data(exec)
    else
      string_cat(tostring(data or ''))
    end
  end
  exec(data)
  return return_str
end

function magiclines(s)
    if s:sub(-1)~="\n" then s=s.."\n" end
    return s:gmatch("(.-)\n")
end

local function code_substitution(data)
    return data:
        gsub("[][]=[][]", ']=]_"%1"_[=['):
        gsub("<%%", "]=]_("):
        gsub("%%>", ")_[=[\n"):
        gsub("[ ]*<%?", "]=] "):
        gsub("[ ]*%?>[ ]*\n", " _[=[")
end

local function code_indentation(data)
  local new_data = {}
  for line in magiclines(data) do
    local new_line = 
      line:
        gsub("^%s+$", ""):
        gsub("^[ ]*%|%-(>+)[ ]*$", "]=]_(inc_indent('%1'))_[=["):
        gsub("^[ ]*%|%-(>+)(.*)$", "]=]_(inc_indent('%1'))_(indent())_[=[\n%2"):
        gsub("%|%-(>+)[ ]*$", "<->]=]_(inc_indent('%1'))_[=[\n"):
        gsub("^[ ]*(<+)%-%|[ ]*$", "]=]_(dec_indent('%1'))_[=["):
        gsub("^[ ]*(.*)(<+)%-%|[ ]*$", "]=]_(dec_indent('%2'))_(indent())_[=[\n%1<->"):
        gsub("^[ ]*(<+)%-%|", "]=]_(dec_indent('%1'))_(indent())_[=[<->"):
        gsub("^[ ]+(.+)$", "]=]_(indent())_[=[%1"):
        gsub("%s*<%->%s*", "")
    table.insert(new_data, new_line)
  end
  return table.concat(new_data, "\n")
end

function template.parse(data, operation)
  local str = 
    "return function(_)" .. 
      "_[=[" ..  operation(data) ..  "]=] " ..
    "end"
--  print("----------------------------")
--  print(str)
--  print("----------------------------")
  return str
end

function template.compile(...)
  return loadstring(template.parse(...))()
end

local function apply_template(string_template, data)
    local code_template_fn = template.compile(string_template, code_substitution)
    local templated_code = template.render(code_template_fn, data)
    local indent_template_fn = template.compile(templated_code, code_indentation)
    return template.render(indent_template_fn, indent_functions)
end

return apply_template
