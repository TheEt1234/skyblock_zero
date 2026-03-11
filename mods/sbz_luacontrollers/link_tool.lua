local waypoint_ids = {}

--- get/set because the meta key name can change, also because types
--- and also because serialization method can change just in case

---@return { [string]: ivec3 }
function sbz_luacs.get_luacontroller_links(meta)
    ---@diagnostic disable-next-line: return-type-mismatch
    return core.deserialize(meta:get_string('luacontroller_links')) or {}
end

function sbz_luacs.set_luacontroller_links(meta, value)
    meta:set_string('luacontroller_links', core.serialize(value))
end

-- The use of "goto" here makes this code luaJIT only
-- And that's fine
local timer = 0
local function render_links(dtime)
    timer = timer + dtime
    if timer < sbz_luacs.render_luacontroller_links_delay then return end
    timer = 0

    for _, v in pairs(waypoint_ids) do
        sbz_api.remove_waypoint(v)
    end

    waypoint_ids = {}
    for _, v in pairs(core.get_connected_players()) do
        local wielded_item = v:get_wielded_item()
        if wielded_item:get_name() ~= 'sbz_luacontroller:luacontroller_linker' then goto continue end

        local itemmeta = wielded_item:get_meta()
        local luacontroller_pos = vector.from_string(itemmeta:get_string('linked'))
        if luacontroller_pos == nil then goto continue end

        local linked_meta = core.get_meta(luacontroller_pos)

        local radius = sbz_luacs.default_linking_range
        vizlib.draw_cube(luacontroller_pos, radius + 0.5, {
            player = v,
            color = 'blue',
            infinite = false,
            time = sbz_luacs.render_luacontroller_links_delay + 0.1,
        })

        local links = sbz_luacs.get_luacontroller_links(linked_meta)

        for name, pos in pairs(links) do
            waypoint_ids[#waypoint_ids + 1] = sbz_api.set_waypoint(pos, {
                name = name,
                dist = 0,
                max_dist = 100,
                precision = 0,
                image = 'visualiser_trail.png^[verticalframe:3:0',
            })
        end
        ::continue::
    end
end

core.register_globalstep(render_links)

local function link_tool_to_luac(stack, pos, placer)
    local node = sbz_api.get_or_load_node(pos)
    local meta = stack:get_meta()
    local name = placer:get_player_name()

    if not sbz_luacs.is_luacontroller(node.name) then
        core.chat_send_player(name, 'That node is not a luacontroller.')
        return
    end

    meta:set_string('linked', vector.to_string(pos))
    core.chat_send_player(name, 'Luacontroller succesfully linked to the linking tool!')

    core.add_particlespawner({
        amount = 1000,
        time = 0.1,
        exptime = 3,
        collisiondetection = true,
        collision_removal = true,
        texture = 'vizlib_particle.png^[colorize:green:255',
        glow = 14,
        pos = pos,
        vel = { min = -vector.new(-3, -3, -3), max = vector.new(-3, -3, -3) },
    })
end

local function err_link_invalid(placer)
    core.chat_send_player(
        placer:get_player_name(),
        'Link is invalid, please link the luacontroller linker to a luacontroller again.'
    )
end

local function make_link(item_meta, pointed_pos, placer)
    local linked = item_meta:get_string('linked')

    local luacontroller_pos = vector.from_string(linked)
    if not luacontroller_pos then return err_link_invalid(placer) end

    local linked_node = sbz_api.get_or_load_node(luacontroller_pos)
    if not sbz_luacs.is_luacontroller(linked_node.name) then return end

    local luacontroller_meta = core.get_meta(luacontroller_pos)
    local linked_range = sbz_luacs.default_linking_range

    if not sbz_luacs.in_square_radius(luacontroller_pos, pointed_pos, linked_range) then
        core.chat_send_player(placer:get_player_name(), 'Outside of the radius.')
        return
    end

    local name = item_meta:get_string 'name'
    if name == '' then
        core.chat_send_player(placer:get_player_name(), 'You need to set a name first (left click).')
        return
    end

    local links = sbz_luacs.get_luacontroller_links(luacontroller_meta)
    links[name] = pointed_pos
    sbz_luacs.set_luacontroller_links(luacontroller_meta, links)
end

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= 'sbz_luacontroller:luacontroller_linker_form' then return end

    local wield_item = player:get_wielded_item()
    if wield_item:get_name() ~= 'sbz_luacontroller:luacontroller_linker' then return end

    wield_item:get_meta():set_string('name', (fields.set_name or ''):trim())
    if not player:get_meta():get_string('target') then return true end

    local target = player:get_meta():get_string('target')
    local target_pos = vector.from_string(target)
    if target_pos == nil then return end

    make_link(wield_item:get_meta(), target_pos, player)
    player:set_wielded_item(wield_item)

    return true
end)

core.register_craftitem('sbz_luacontroller:luacontroller_linker', {
    description = 'Luacontroller Linker',
    short_description = 'Luacontroller Linker',
    info_extra = {
        'Right click: asks for a name, links pointed block',
        'Left click: use the previous name, and links pointed block',
        'Aux1 + right click/left click: links to pointed luacontroller',
        "If you hold it, it will show all the links and the luacontroller's radius",
    },
    inventory_image = 'luacontroller_linker.png',
    range = 10,
    on_place = function(stack, placer, pointed)
        if pointed.type ~= 'node' then return end
        if core.is_protected(pointed.under, placer:get_player_name()) then
            core.record_protection_violation(pointed.under, placer:get_player_name())
            return
        end
        if placer:get_player_control().aux1 == false then
            local target = pointed.under
            core.show_formspec(
                placer:get_player_name(),
                'sbz_luacontroller:luacontroller_linker_form',
                'field[set_name;The name of the link;]'
            )
            if pointed.type ~= 'node' then
                placer:get_meta():set_string('target', '')
                return
            end
            placer:get_meta():set_string('target', vector.to_string(target))
        else
            if pointed.type ~= 'node' then return end
            link_tool_to_luac(stack, pointed.under, placer)
        end
        return stack
    end,
    on_use = function(stack, placer, pointed)
        if pointed.type ~= 'node' then return end
        if core.is_protected(pointed.under, placer:get_player_name()) then
            core.record_protection_violation(pointed.under, placer:get_player_name())
            return
        end
        if placer:get_player_control().aux1 == false then
            local target = pointed.under
            make_link(stack:get_meta(), target, placer)
        else
            link_tool_to_luac(stack, pointed.under, placer)
        end
        return stack
    end,
    groups = { ui_luacs = 1 },
    stack_max = 1,
})

do
    local Luacontroller_Linker = 'sbz_logic:luacontroller_linker'
    local CC = 'sbz_resources:compressed_core_dust'
    local WC = 'sbz_resources:warp_crystal'
    core.register_craft({
        output = Luacontroller_Linker,
        recipe = {
            { CC, CC, CC },
            { CC, WC, CC },
            { CC, CC, CC },
        },
    })
end
