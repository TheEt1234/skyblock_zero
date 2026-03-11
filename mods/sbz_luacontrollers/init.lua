---@diagnostic disable-next-line: lowercase-global I don't get why that's even a thing, i mean i guess its helpful
sbz_luacs = {
    -- == Linking configuration == --

    max_luacomm_message_length = 32 * 1024,
    default_linking_range = 8, -- (r*2+1)**2 nodes
    render_luacontroller_links_delay = 0.5, -- Decides how fast do luacontroller links render

    -- == Sandbox configuration == --
    -- (cannot be changed in runtime for silly reasons, if that's an issue those silly reasons can go away, the sandbox_config function is a local in env.lua that actually controls these)

    max_string_len = 64000, -- Functions will refuse to work if the string length exceedes this
    max_loadstring_code_length = 10000, -- tl will refuse to transpile if code length exceedes this limit.
    time_limit = 8, -- miliseconds

    -- == Environment configuration == --

    chat_debug_message_limit = 200,

    -- == Misc luac related configuration == --
    max_memsize = 1024 * 8,
    max_us_per_second = 30 * 1000,
}

sbz_luacs.log = function(msg)
    if sbz_api.debug then core.log('action', ('[sbz_luacontroller] %s'):format(msg)) end
end

--- TODO: sbz_luacs.kill_itemstacks
--- Takes in an inventory/object, normalizes all itemstacks to tables

local MP = core.get_modpath('sbz_luacontroller')

dofile(MP .. '/utils.lua') -- INFO: Refactor done
dofile(MP .. '/luacomm.lua') -- INFO: Refactor done, need to refactor all all devices to use it
dofile(MP .. '/link_tool.lua') -- INFO: Refactor done, though may want to change the functionality

dofile(MP .. '/env.lua') -- INFO: Refactor in progress
--- FIXME: MAKE sure all luacontroller devices USE ABSOLUTE POSITIONS

dofile(MP .. '/sandbox.lua')
dofile(MP .. '/yield_behavior.lua')
dofile(MP .. '/editor.lua')

sbz_api.register_stateful_machine('sbz_luacontroller:luacontroller', {
    tiles = { 'luacontroller_top.png', 'luacontroller_top.png', 'luacontroller.png' },
    description = 'Lua Controller',
    info_extra = {
        'The most complex block in this game.',
    },
    autostate = false,
    after_place_node = function(pos, placer, stack, pointed)
        core.get_meta(pos):set_string('owner', placer:get_player_name())
        pipeworks.after_place(pos)
    end,

    action = sbz_luacs.on_tick,
    action_subtick = function(pos, node, meta, supply, demand)
        sbz_luacs.send_event_to_sandbox(pos, { type = 'subtick', supply = supply, demand = demand })
        return 0
    end,

    on_construct = function(pos)
        local meta = core.get_meta(pos)
        sbz_luacs.ui(pos, meta)
    end,

    _luacomm_receive = function(pos, msg, from_pos)
        sbz_luacs.send_event_to_sandbox(pos, {
            type = 'receive',
            msg = msg,
            from_pos = from_pos,
        })
    end,

    on_turn_off = sbz_luacs.on_turn_off,
    after_dig_node = sbz_luacs.on_turn_off,

    on_receive_fields = sbz_luacs.on_receive_fields,

    groups = {
        sbz_luacontroller = 1,
        matter = 1,
        ui_luacs = 1,
        tubedevice = 1,
        tubedevice_receiver = 1,
        sbz_machine_subticking = 1,
    },
}, {
    light_source = 14,
})

function sbz_luacs.is_luacontroller(name)
    return name == 'sbz_luacontroller:luacontroller_on' or name == 'sbz_luacontroller:luacontroller_off'
end

local function move_luac(moved_node)
    if not sbz_luacs.is_luacontroller(core.get_node(moved_node.pos).name) then return end

    local linked_meta = core.get_meta(moved_node.pos)
    local links = sbz_luacs.get_luacontroller_links(linked_meta)

    for name, pos in pairs(links) do
        links[name] = pos - moved_node.oldpos + moved_node.pos
    end

    sbz_luacs.set_luacontroller_links(linked_meta, links)

    local id = linked_meta:get_string('ID')
    local sandbox = sbz_luacs.sandboxes[id]
    if sandbox then sbz_luacs.update_sandbox_pos(sandbox, moved_node.pos) end
end

mesecon.register_on_mvps_move(function(moved)
    for i = 1, #moved do
        local moved_node = moved[i]
        if sbz_luacs.is_luacontroller(moved_node.node.name) then sbz_luacs.delay(0, move_luac, moved_node) end
    end
end)

do -- Lua Controller recipe scope
    local Lua_Controller = 'sbz_logic:lua_controller'
    local LC = 'sbz_resources:lua_chip'
    local DD = 'sbz_logic:data_disk'
    local RS = 'sbz_resources:ram_stick_1mb'
    local WC = 'sbz_resources:warp_crystal'
    core.register_craft {
        output = Lua_Controller,
        recipe = {
            { LC, DD, LC },
            { LC, RS, LC },
            { LC, WC, LC },
        },
    }
end
