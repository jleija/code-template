local function new_template(config)

    local template_level = 0

    config = config or {}
    config.initial_indentation_depth = config.initial_indentation_depth or 0

    local function parse(text, operation)
      local str = 
        "return function(_)" .. 
          "_[=[" ..  operation(text) ..  "]=] " ..
        "end"
--      print("----------------------------")
--      print(str)
--      print("----------------------------")
      return str
    end

    local function compile(text, operation)
      return loadstring(parse(text, operation))()
    end

    local function render(text, args)
      local return_str = ""
      local function string_cat(x)
          return_str = return_str .. x
      end

      local function exec(text)
        if type(text) == "function" then
          local args = args or {}
          setmetatable(args, { __index = _G })
          setfenv(text, args)
          text(exec)
        else
          string_cat(tostring(text or ''))
        end
      end
      exec(text)
      return return_str
    end

    local function each_line(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
    end

    local function code_substitution(text)
        return text:
            gsub("[][]=[][]", ']=]_"%1"_[=['):
            gsub("<%|%%", "<|\n]=]_("):
            gsub("%%%|>", ")_[=[\n\n|>"):
            gsub("<%%", "]=]_("):
            gsub("%%>", ")_[=[\n"):
            gsub("<%|%?", "<@\n]=] "):
            gsub("%s*<%?([^%?]*)%?%|>", "\n]=] %1 _[=[\n@>"):
            gsub("<%?", "]=] "):
            gsub("%?>", " _[=[")
    end

    local function make_spaces(count)
        return string.rep(" ", count)
    end

    local function reindent(line, level)
        if level.spaces_to_remove then
            local shortened_line = line:gsub("^" .. level.spaces_to_remove, "")
            return shortened_line
        end
        if level.spaces_to_add then
            return level.spaces_to_add .. line
        end
        return line
    end

    local level = {
        spaces_to_add = false,
        spaces_to_remove = false,
        depth = 0,
        offset = false
    }

    local function code_indentation(text)
        local indented_lines = {}

        for line in each_line(text) do
            local indentation_spaces = line:match("^(%s*)<%|") 
            if indentation_spaces then
                local new_level = {
                    depth = #indentation_spaces - (level.offset or 0),
                    spaces_to_add = false,
                    spaces_to_remove = false,
                    offset = false,
                    prev = level
                }
                level = new_level
            elseif line:match("%|>") then
                level = level.prev
                assert(level)
            elseif line:match("^(%s*)<@") then
                local indentation_spaces = line:match("^(%s*)<@") 
                local new_level = {
                    depth = #indentation_spaces - (level.offset or 0),
                    offset = false,
                    spaces_to_add = false,
                    spaces_to_remove = false,
                    prev = level
                }
                level = new_level
            elseif line:match("@>") then
                level = level.prev
                assert(level)
            else
                if not level.spaces_to_add and not level.spaces_to_remove then
                    local spaces = line:match("^(%s*)(.*)$")
                    if spaces and #spaces > level.depth then
                        level.offset = #spaces - level.depth
                        level.spaces_to_remove = make_spaces(level.offset)
                    elseif spaces and #spaces < level.depth then
                        level.offset = level.depth - #spaces
                        level.spaces_to_add = make_spaces(level.offset)
                    end
                end
                table.insert(indented_lines, reindent(line, level))
            end
        end

        if config.initial_indentation_depth > 0 then
            local initial_indentation = make_spaces(config.initial_indentation_depth)
            for i=1,#indented_lines do
                indented_lines[i] = initial_indentation .. indented_lines[i]
            end
        end

        return table.concat(indented_lines, "\n")
    end

    local function apply_template(string_template, data)
        template_level = template_level + 1

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
