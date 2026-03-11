-- It has been decided (by me :3) that everything exposed to the luacontroller should prefer an absolute position
-- And also that everything SHOULD PREFER TO ERROR LOUDLY instead of just returning ok, errmsg

local sandbox_config = {
    max_string_len = sbz_luacs.max_string_len,
    limit_function = slua.get_default_limit_function(sbz_luacs.time_limit, 'timeout'),
    max_loadstring_code_length = sbz_luacs.max_loadstring_code_length,
}

-- do this every time a sandbox is started
-- its so that it wont unjustly time out because of some other sandbox
-- so like, its kinda-half-ish-maybe deterministic
function sbz_luacs.refresh_limit_function()
    sandbox_config.limit_function = slua.get_default_limit_function(sbz_luacs.time_limit, 'timeout')
end

-- Previously there used to be make_safe functions that forced whatever object there was to be safe to serialize
-- I think it's better to error out instead of silently replacing things

function sbz_luacs.serialize_mem(mem, max)
    local size = sbz_luacs.object_size(mem, nil, true)

    if size == false then
        return false,
            'The mem table could not be serialized. You must not include any functions, threads, cdata or userdata in the mem table.'
    end

    if size > max then
        return false, string.format('You are trying to store too much data in the mem table (%s/%s bytes)', size, max)
    end

    local serialized_mem = core.serialize(mem)
    if #serialized_mem > max then
        -- string buffers when? (they don't solve the problem at all and would introduce more restrictions)
        return false,
            string.format(
                "You are trying to store too much data in the mem table (%s/%s bytes). Luanti's serialization may be inefficient, especially with binary data.",
                #serialized_mem,
                max
            )
    end

    return serialized_mem
end

local make_safer = function(f)
    return slua.make_safer(f, sandbox_config)
end

function sbz_luacs.get_the_get_node_function(sandbox)
    return make_safer(function(pos)
        local range_allowed = sbz_luacs.range_check(sandbox.pos, pos)
        if not range_allowed then
            return false, 'The node you are trying to get is too far away or is protected by someone else.'
        end
        return core.get_node(pos)
    end)
end

function sbz_luacs.get_chat_debug_function(sandbox, owner)
    return make_safer(function(msg)
        if type(msg) ~= 'string' then error('In chat_debug(msg), the msg must be a string!') end
        if #msg > sbz_luacs.chat_debug_message_limit then error('Message too large') end
        if owner == '' then error('This luacontroller does not have an owner, you need to rebuild it.') end
        if not core.is_protected(sandbox.pos, '') or core.is_protected(sandbox.pos, owner) then
            error('Luacontroller must be protected by ' .. owner .. ' for chat_debug to work')
        end
        if not core.get_player_by_name(owner) then return false end -- not online

        core.chat_send_player(
            owner,
            string.format('[Luacontroller @%s] %s', vector.to_string(sandbox.pos), core.colorize('lime', msg))
        )
        return true
    end)
end

local function get_read_mem(sandbox)
    return make_safer(function()
        return core.deserialize(sandbox.meta:get_string('mem')) or {}
    end)
end

local function get_write_mem(sandbox)
    return make_safer(function(mem_data)
        local mem, errmsg = sbz_luacs.serialize_mem(mem_data, sbz_luacs.max_memsize)
        if errmsg then error(errmsg) end
        sandbox.meta:set_string('mem', mem)
        sandbox.meta:mark_as_private('mem')
        return true
    end)
end

-- absolute position now
function sbz_luacs.update_env_links(meta, env)
    env.links = sbz_luacs.get_luacontroller_links(meta)
end

---@param sandbox {pos: vector, meta:core.NodeMetaRef} # Cannot get sandbox.env obviously
function sbz_luacs.get_env(sandbox)
    local env = {}
    slua.env.init_environment(env, sandbox_config)
    slua.env.basic_env(env, sandbox_config)
    slua.env.add_luanti_utils(env, sandbox_config)

    sbz_luacs.update_env_links(sandbox.meta, env)

    local function wait_for_event_type(event_type)
        local ignored_events = {}
        while true do
            local e = coroutine.yield()
            ignored_events[#ignored_events + 1] = e
            if e.type == event_type then return ignored_events end
        end
    end

    local owner = sandbox.meta:get_string('owner') -- owner cannot change (yet, if it did its going to sandbox.owner and stuff will need to get rewritten)

    for k, v in pairs {
        yield = coroutine.yield,
        wait_for_event_type = wait_for_event_type,
        chat_debug = sbz_luacs.get_chat_debug_function(sandbox, owner),

        -- no i am not intentionally making my code look like Java
        -- this is needed
        -- sandbox.pos can change and will change
        -- (btw it needs to be copied, it not being copied would be a vurnability)
        get_pos = function()
            return vector.copy(sandbox.pos)
        end,

        wait = function(t)
            local e = coroutine.yield({
                type = 'wait',
                time = t,
            })
            if e.type == 'wait' then return { e } end
            return wait_for_event_type('wait')
        end,

        luacomm_send = make_safer(function(pos, msg)
            if not sbz_luacs.is_vector(pos) then error('luacomm_send supplied with an invalid position') end
            local cost = sbz_luacs.object_size(msg, nil, true)

            if cost == false then
                error(
                    'The message you are sending cannot be serialized. Your message cannot contain functions, userdata, cdata or threads.'
                )
            end
            if cost > sbz_luacs.max_luacomm_message_length then
                error(
                    ('The message you are sending is too large (%s/%s bytes)'):format(
                        cost,
                        sbz_luacs.max_luacomm_message_length
                    )
                )
            end

            local range_allowed = sbz_luacs.range_check(sandbox.pos, pos)
            if not range_allowed then error('The position you are sending to is too far away or is protected.') end

            sbz_luacs.delay(0, sbz_luacs.delayable_functions.luacomm, pos, msg, sandbox.pos)
            return true
        end),

        get_node = sbz_luacs.get_the_get_node_function(sandbox),

        -- Infinite range xD
        is_protected = make_safer(function(pos, who)
            if not sbz_luacs.is_vector(pos) then error('is_protected supplied with an invalid position.') end
            -- local range_allowed = sbz_luacs.range_check(sandbox.pos, pos) -- range_check might check for protection, but uncomment these lines if you want that behavior, i haven't decided on it yet
            -- if not range_allowed then error('The position you are checking is too far away') end
            return core.is_protected(pos, who or owner)
        end),

        read_mem = get_read_mem(sandbox),
        write_mem = get_write_mem(sandbox),
    } do
        env[k] = v
    end
    return env
end
