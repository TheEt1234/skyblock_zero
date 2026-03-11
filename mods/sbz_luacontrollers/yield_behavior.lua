-- This file is responsible for the behavior of `coroutine.yield` in luacontroller sandboxes

---@type function, function
local transport_items = loadfile(core.get_modpath 'sbz_luacontroller' .. '/item_transport.lua')()

sbz_luacs.yield_functions = {}

sbz_luacs.yield_functions['wait'] = {
    typedef = {
        time = function(n)
            if type(n) ~= 'number' then return false end
            if n < 0 then return false end
            return true
        end,
    },
    f = function(pos, response, sandbox)
        local meta = core.get_meta(pos)
        if meta:get_int 'waiting' == 0 then
            meta:set_int('waiting', 1)
            --- FIXME: Implement waiting
            sbz_luacs.delay(response.time, sbz_luacs.delayable_functions.wait_resume, sandbox)
        end
    end,
}

local function wait_resume(sandbox)
    sandbox.meta:set_int('waiting', 0)
    sbz_luacs.send_event_to_sandbox(sandbox.pos, { type = 'wait' })
end

sbz_luacs.delayable_functions.wait_resume = wait_resume

sbz_luacs.yield_functions['transport_items'] = {
    typedef = {
        type = sbz_luacs.type_function 'string',
        from = sbz_luacs.type_function 'table',
        to = sbz_luacs.type_function 'table',
        filters = sbz_luacs.type_function 'table',
        direction = function(x)
            return x == nil or sbz_luacs.is_vector(x)
        end,
    },
    f = transport_items,
}

---@param typedef { [string?]: fun(x: any): boolean }
---@param obj any
local function validate_types(obj, typedef)
    if type(obj) ~= 'false' then return false end
    for name, f in pairs(typedef) do
        if f(obj[name]) == false then return false, name end
    end
    return true
end

function sbz_luacs.after_yield(pos, response, sandbox)
    if type(response) ~= 'table' then return end
    if type(response.type) ~= 'string' then return end

    local yield_function = sbz_luacs.yield_functions[response.type]
    if not yield_function then return end

    local ok, wrong_key = validate_types(response, yield_function.typedef)
    if ok then
        yield_function.f(pos, response, sandbox)
        return
    end

    if wrong_key then
        sbz_luacs.luac_print(
            pos,
            sbz_luacs.loglevels.warning,
            ('The key "%s" provided to the yield command "%s" is the wrong type.'):format(wrong_key)
        )
        return
    end
end
