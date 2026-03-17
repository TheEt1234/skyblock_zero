-- Use with sbz_luacs.delay
-- Example: sbz_luacs.delay(0, sbz_luacs.dalayable_functions.send_event, sandbox, event)
-- Not a string because keeping it simple allows you to more easily track down the function in your editor
--  if you have a language server
sbz_luacs.delayable_functions = {}

-- For functions that are supposed to be delayed a bit (to not cause infinite recursive loops for example)
-- currently the same as core.after, it is unlikely that this will change, but in case there are some special
--   requirements then this can change (example: lag limiting)
function sbz_luacs.delay(t, f, ...)
    return core.after(t, f, ...)
end

function sbz_luacs.in_square_radius(pos1, pos2, rad)
    local x1, y1, z1 = pos1.x, pos1.y, pos1.z
    local x2, y2, z2 = pos2.x, pos2.y, pos2.z

    local a = math.abs
    local dx, dy, dz = a(x1 - x2), a(y1 - y2), a(z1 - z2)

    if dx > rad or dy > rad or dz > rad then return false end
    return true
end

function sbz_luacs.range_check(luac_pos, pos2)
    local meta = core.get_meta(luac_pos)
    local linking_range = sbz_luacs.default_linking_range
    local owner = meta:get_string('owner')

    return sbz_luacs.in_square_radius(luac_pos, pos2, linking_range) and not core.is_protected(pos2, owner)
end

function sbz_luacs.kill_itemstacks(t)
    for k, v in pairs(t) do
        if type(v) == 'table' then
            t[k] = sbz_luacs.kill_itemstacks(v)
        elseif type(v) == 'userdata' and v.to_table then
            t[k] = v:to_table()
        end
    end
    return t
end

function sbz_luacs.is_vector(any)
    if type(any) ~= 'table' then return false end

    for k, v in pairs(any) do
        if not (k == 'x' or k == 'y' or k == 'z') then return false end
        if type(v) ~= 'number' then return false end
    end
    if type(any.x) ~= 'number' or type(any.y) ~= 'number' or type(any.z) ~= 'number' then return end
    return true
end

local type_functions = {}
function sbz_luacs.type_function(t)
    if type_functions[t] then return type_functions[t] end
    type_functions[t] = function(x)
        return type(x) == t
    end
    return type_functions[t]
end

-- Inspired by mesecons
local function object_size_internal(object, max_size, serializable, seen)
    local object_type = type(object)
    if object_type == 'number' then
        return 8
    elseif object_type == 'boolean' then
        return 1
    elseif object_type == 'string' then
        return #object + 25
    elseif object_type == 'table' then
        if seen[object] then return 0 end
        seen[object] = true

        local size = 8
        for key, value in pairs(object) do
            local size_k = object_size_internal(key, max_size, serializable, seen)
            if size_k == false then return false end
            local size_v = object_size_internal(value, max_size, serializable, seen)
            if size_v == false then return false end

            size = size + size_k + size_v
            if max_size and size > max_size then return false end -- Its worth to do the check here
        end
        return size
    else
        if serializable then return false end
        return 0
    end
end

--- - Returns the size in bytes
--- - Stops if size of object is bigger than `size`
--- - Object must also be serializable for the size to be accurate, to check if the object is serializable, set `serializable` to true
---    - What counts as "serializable" is determined by what you can serialize in luanti, without insecure environment
--- - Functions are considered un-serializable
--- - Also cdata's uint_64 or int64 are considered unserializable too (Even if i could program my own serializer, i dont want that)
---@param object any
---@param max_size integer? Bytes, returns false if `object` size is above that, does not return a complete size
---@param serializable boolean? Makes the function return false if object is not serializable
---@return integer|false bytes
function sbz_luacs.object_size(object, max_size, serializable)
    local object_size = object_size_internal(object, max_size, serializable, {})
    if object_size == false then return false end
    if max_size and object_size > max_size then return false end
    return object_size
end

function sbz_luacs.stringify_syntax_error(syntax_errors, code)
    if type(syntax_errors) == 'string' then return syntax_errors end

    local code_split = code:split('\n')

    local out = {}
    for _, err in ipairs(syntax_errors) do
        local relevant_line = code_split[err.y]
        if relevant_line and #relevant_line < 100 then
            table.insert(out, ('> %s'):format(relevant_line))
            table.insert(out, ('%s^'):format((' '):rep(err.x + 1)))
        end
        table.insert(out, string.format('%s:%s:%s: %s', err.filename, err.x, err.y, err.msg))
        table.insert(out, ' ')
    end

    return table.concat(out, '\n')
end
