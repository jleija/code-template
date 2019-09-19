local function new_template(config)

    local template_level = 0

    config = config or {}

    local indentation_depth = config.initial_indentation_depth or 0
    local indent_spaces = config.indent or "  "

    local indent_functions = {}
    local saved_indents = {}
    function indent_functions.indent()
        local saved_indent = saved_indents[indentation_depth]
        if saved_indent then return saved_indent end

        local indents = {}
        for i=1, indentation_depth do
            table.insert(indents, indent_spaces)
        end
        local indentation = table.concat(indents, "")
        saved_indents[indentation_depth] = indentation
        return indentation
    end

    function indent_functions.inc_indent(indents)
        indentation_depth = indentation_depth + #indents
        return ""
    end

    function indent_functions.dec_indent(indents)
        indentation_depth = indentation_depth - #indents
        return ""
    end

    function render(data, args)
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
            gsub("<%?", "]=] "):
            gsub("%?>", " _[=[")
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
            gsub("^[ ]*([^<]*)(<+)%-%|[ ]*$", "]=]_(dec_indent('%2'))_(indent())_[=[\n%1<->"):
            gsub("^[ ]*(<+)%-%|", "]=]_(dec_indent('%1'))_(indent())_[=[<->"):
            gsub("^[ ]+(.+)$", "]=]_(indent())_[=[%1"):
            gsub("%s*<%->%s*", "")
        table.insert(new_data, new_line)
      end
      return table.concat(new_data, "\n")
    end

    function parse(data, operation)
      local str = 
        "return function(_)" .. 
          "_[=[" ..  operation(data) ..  "]=] " ..
        "end"
--      print("----------------------------")
--      print(str)
--      print("----------------------------")
      return str
    end

    function compile(...)
      return loadstring(parse(...))()
    end

    local function apply_template(string_template, data)
        template_level = template_level + 1
        if template_level == 1 then
            indentation_depth = config.initial_indentation_depth or 0
            indent_spaces = config.indent or "  "
        end

        local code_template_fn = compile(string_template, code_substitution)
        local res = render(code_template_fn, data)
        
        if template_level == 1 then
            local indent_template_fn = compile(res, code_indentation)
            res = render(indent_template_fn, indent_functions)
        end
        template_level = template_level - 1
        return res
    end

    return apply_template
end

return new_template
