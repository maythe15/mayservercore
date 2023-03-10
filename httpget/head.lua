--http calls

mschttp={}
function mschttp.to_json(value)
    local result = ""
    if type(value) == "table" then
        local is_numeric, last_i = #value > 0, 0
        for i,_ in pairs(value) do
            last_i = last_i + 1
            is_numeric = is_numeric and type(i) == "number" and i == last_i
        end
        if is_numeric then
            for _, v in ipairs(value) do
                result = result .. "," .. mschttp.to_json(v)
            end
            result = "[" .. result:sub(2,#result) .. "]"
        else
            for k,v in pairs(value) do
                result = result .. "," .. mschttp.to_json(k) .. ":" .. mschttp.to_json(v)
            end
            result = "{" .. result:sub(2,#result) .. "}"
        end
    elseif type(value) == "number" then
        result = tostring(value)
    elseif type(value) == "boolean" then
        result = value and "true" or "false"
    elseif value == nil then
        result = "none"
    else
        result = string.format("%q", tostring(value)):gsub("\n", "n")
    end
    return result
end
function mschttp.escape(s)
    return (s:gsub("[^%w%d%-%._~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end
function mschttp.from_json(json)
    local pos, current, escape_characters = 0, "", {a="\a", b="\b", f="\f", n="\n", r="\r", t="\t", v="\v"}

    function advance()
        pos = pos + 1
        current = json:sub(pos, pos)
        if current == "" then
            current = nil
        end
    end

    function decode_string()
        local result = ""
        advance()
        while current ~= '"' do
            if current == "\\" then
                advance()
                result = result .. (escape_characters[current] or current)
                advance()
            else
                result = result .. current
                advance()
            end
        end
        advance()
        return result
    end

    function decode_object()
        local result
        if current == "[" then
            local result = {}
            advance()
            while current ~= "]" do
                table.insert(result, decode_object())
                if current == "," then
                    advance()
                end
            end
            advance()
            return result
        elseif current == "{" then
            local result = {}
            advance()
            while current ~= "}" do
                local key = decode_string()
                advance()
                local value = decode_object()
                result[key] = value
                if current == "," then
                    advance()
                end
            end
            advance()
            return result
        elseif current == "t" then
            result = true
            advance()advance()advance()advance()
        elseif current == "f" then
            result = false
            advance()advance()advance()advance()advance()
        elseif current == "n" then
            result = nil
            advance()advance()advance()advance()
        elseif current == '"' then
            result = decode_string()
        else
            local combined = ""
            while current ~= "," and current ~= "}" and current ~= "]" do
                combined = combined .. current
                advance()
            end
            return tonumber(combined)
        end
        return result
    end
    advance()
    return decode_object()
end
