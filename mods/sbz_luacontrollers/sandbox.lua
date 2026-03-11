-- btw "us_taken" means "microseconds_taken" in this codebase
-- you are welcome

--- pos/meta should be updated on mov
---@class luac_sandbox
---@field pos vector
---@field meta table|userdata
---@field thread thread
---@field env table
---@field id string

---@type { [string]: luac_sandbox }
sbz_luacs.sandboxes = {}

function sbz_luacs.update_sandbox_pos(sandbox, new_pos)
    sandbox.pos = vector.copy(new_pos)
    sandbox.meta = core.get_meta(new_pos)
end

function sbz_luacs.is_on(meta)
    return meta:get_int('luac_on') == 1
end

-- Use sbz_luacs.set_state to turn off the sandbox, not this
-- This is used by sbz_luacs.set_state, and called manually when the luac is dug FIXME: ACTUALLY DO THAT
function sbz_luacs.remove_sandbox(pos, meta)
    local id = meta:get_string('ID')
    sbz_luacs.sandboxes[id] = nil
    meta:set_string('ID', '')
end

function sbz_luacs.set_state(pos, meta, state)
    local current_state = meta:get_int('luac_on')
    if current_state ~= (state and 1 or 0) then -- if the current state is going to get changed
        if state == false then
            sbz_luacs.remove_sandbox(pos, meta)
        elseif state == true then
            sbz_luacs.create_sandbox(pos, meta)
        end
    end
    meta:set_int('luac_on', state and 1 or 0)
    sbz_luacs.ui(pos, meta) -- NOTE: Is this too annoying?
end

function sbz_luacs.can_run_sandbox(meta)
    if sbz_luacs.is_on(meta) == false then return false end
    if meta:get_int 'bill' ~= 0 then return false end
    if (meta:get_float 'us_used') > sbz_luacs.max_us_per_second then return false end
    return true
end

function sbz_luacs.create_sandbox(pos, meta)
    if not sbz_luacs.can_run_sandbox(meta) then return false end

    local id = tostring(math.random(-999000, 999000)) -- good enough probably, i hope

    local sandbox = {
        pos = pos,
        meta = meta,
        id = id,
    }

    sandbox.env = sbz_luacs.get_env(sandbox)

    -- Not to be confused with sbz_luacs.create_sandbox, or the `sandbox` variable that is already partially made, this is its own thing
    local thread, syntax_errors = slua.create_sandbox {
        code = meta:get_string 'code',
        env = sandbox.env,
        chunkname = 'main',
    }

    if syntax_errors then
        sbz_luacs.luac_error(pos, 'OWCHIE! THERE WERE SYNTAX ERRORS! I hate syntax errors! ..' .. dump(syntax_errors))
        return
    end

    sandbox.thread = thread

    sbz_luacs.sandboxes[id] = sandbox

    meta:set_string('ID', id)
    meta:mark_as_private 'ID'

    sbz_luacs.log('Created sandbox @' .. vector.to_string(pos))

    local ok = sbz_luacs.send_event_to_sandbox(pos, { type = 'program' })

    if not ok then return false end
    return id
end

function sbz_luacs.send_event_to_sandbox(pos, event)
    local t0 = sbz_api.clock_ms()

    local meta = core.get_meta(pos)
    if not sbz_luacs.can_run_sandbox(meta) then return false end

    local id = meta:get_string 'ID'

    local sandbox = sbz_luacs.sandboxes[id]

    -- *Automatically create a sandbox if there isn't one*
    if not sandbox then
        local new_id = sbz_luacs.create_sandbox(pos, meta)
        if not new_id then return false end

        meta:set_string('ID', new_id)

        id = new_id
        sandbox = sbz_luacs.sandboxes[id]
    end

    -- just in case it moved or something, unlikely
    sbz_luacs.update_sandbox_pos(sandbox, pos)
    sbz_luacs.update_env_links(meta, sandbox.env)

    -- Actually run the thing
    local ok, errmsg = slua.run_sandbox(sandbox.thread, sandbox.env, event)

    meta:set_float('us_used', meta:get_float 'us_used' + (sbz_api.clock_ms() - t0))

    sbz_luacs.log('Sent event to: ' .. vector.to_string(pos))

    if not ok then
        sbz_luacs.luac_error(pos, errmsg)

        -- This means something like an error killed it
        -- So just turn it off
        if coroutine.status(sandbox.thread) == 'dead' then sbz_luacs.set_state(pos, meta, false) end
        return false
    else
        local value = errmsg
        sbz_luacs.after_yield(pos, value, id)

        return true
    end
end

sbz_luacs.delayable_functions.send_event_to_sandbox = sbz_luacs.send_event_to_sandbox

function sbz_luacs.calculate_bill(us_used)
    return math.ceil(us_used) * 4
end

local function format_lag(x)
    return tostring(math.floor(x / 1000)) .. 'ms'
end

-- switching station action
function sbz_luacs.on_tick(pos, _, meta, supply, demand)
    if sbz_luacs.is_on(meta) == false then
        meta:set_string('infotext', 'Off.')
        return 0
    end

    local old_bill = meta:get_int 'bill'

    if old_bill ~= 0 then
        local bill = old_bill
        local result = math.max(0, bill - (supply - demand))
        meta:set_int('bill', result)
        return math.max(0, meta:get_int 'bill' - result)
    end

    local us_taken = meta:get_float 'us_taken'
    local bill = sbz_luacs.calculate_bill(us_taken)

    local net = supply - demand
    local power_consumed

    if net < bill then -- bill needs to get paid over multiple ticks, that means that your luacontroller will also not work
        local result = math.max(0, bill - net)
        meta:set_int('bill', result)
        power_consumed = math.max(0, meta:get_int 'bill' - result)
    else
        meta:set_int('bill', 0)
        power_consumed = bill
    end

    meta:set_string(
        'infotext',
        string.format(
            'Lag: %s\nBill: %s Cj\nCan run: %s',
            format_lag(us_taken),
            bill,
            sbz_luacs.can_run_sandbox(meta) and 'yes' or 'no'
        )
    )

    meta:set_float('us_taken', 0)
    sbz_luacs.send_event_to_sandbox(pos, { type = 'tick', supply = supply, demand = demand })

    return power_consumed
end
