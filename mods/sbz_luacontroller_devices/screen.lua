-- Inspired by the original digiscreen code by cheapie, at https://cheapiesystems.com/git/digiscreen/tree/, that is public domain

local max_resolution = 32
local z_fighting_tolerance = 0.001

local function remove_entity(pos)
    local entities_nearby = core.get_objects_inside_radius(pos, 0.5)
    for _, i in pairs(entities_nearby) do
        if i:get_luaentity() and i:get_luaentity().name == 'sbz_luacontroller_devices:screen_entity' then i:remove() end
    end
end

local function generate_texture(serialized_data)
    if type(serialized_data) ~= 'string' then return end
    local data = core.deserialize(serialized_data)
    if type(data) ~= 'table' then return end

    local bincolors = {}
    local index = #bincolors + 1
    local size = math.min(max_resolution, #data)

    local black = core.colorspec_to_bytes('#000000')
    for y = 1, size do
        if type(data[y]) ~= 'table' then data[y] = {} end
        for x = 1, size do
            bincolors[index] = data[y][x] or black
            index = index + 1
        end
    end

    local img
    local ok, _ = pcall(function()
        img = core.encode_png(size, size, table.concat(bincolors), 1)
    end)

    if not ok then return end

    return 'blank.png^[invert:a^[png:' .. core.encode_base64(img)
end

local function update_display(pos)
    remove_entity(pos)

    local meta = core.get_meta(pos)
    local data = meta:get_string('data')
    local entity = core.add_entity(pos, 'sbz_luacontroller_devices:screen_entity')
    if not entity then return end

    local dir = core.fourdir_to_dir(core.get_node(pos).param2)
    local texture = 'blank.png^[invert:a'

    texture = generate_texture(data) or texture
    entity:set_properties({ textures = { texture } })
    entity:set_yaw((dir.x ~= 0) and math.pi / 2 or 0)
    entity:set_pos(vector.add(pos, vector.multiply(dir, 0.4 - z_fighting_tolerance)))
end

core.register_entity('sbz_luacontroller_devices:screen_entity', {
    initial_properties = {
        visual = 'upright_sprite',
        physical = false,
        collisionbox = { 0, 0, 0, 0, 0, 0 },
        textures = { 'blank.png^[invert:a' },
    },
    on_activate = function(self)
        self.object:set_armor_groups {
            jumpdrive_movable = 1,
        }
    end,
})

core.register_node('sbz_luacontroller_devices:screen', {
    description = 'Screen',
    info_extra = {
        'Use with luacontroller.',
    },
    tiles = {
        'blank.png^[invert:rgba^[colorize:grey',
        'blank.png^[invert:rgba^[colorize:grey',
        'blank.png^[invert:rgba^[colorize:grey',
        'blank.png^[invert:rgba^[colorize:grey',
        'blank.png^[invert:rgba^[colorize:grey',
        'blank.png^[invert:rgba^[colorize:grey',
    },
    use_texture_alpha = 'clip',
    drawtype = 'nodebox',
    paramtype = 'light',
    paramtype2 = '4dir',
    sunlight_propagates = true,
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local display = { { core.colorspec_to_bytes('black') } }
        meta:set_string('data', core.serialize(display))
        update_display(pos)
    end,
    on_destruct = remove_entity,
    on_punch = function(screenpos, _, player)
        if not player then return end
        if player.is_fake_player then return end

        local m = core.get_meta(screenpos)
        local disp = core.deserialize(m:get_string('data'))
        if type(disp) ~= 'table' then return end
        local size = math.min(max_resolution, #disp)

        local subscribed = vector.from_string(m:get_string('subscribed'))
        if subscribed == nil then return end

        local eye_pos = sbz_api.get_pos_with_eye_height(player)
        local look_dir = player:get_look_dir()
        local distance = vector.distance(eye_pos, screenpos)
        local end_pos = vector.add(eye_pos, vector.multiply(look_dir, distance + 1))
        local ray = core.raycast(eye_pos, end_pos, true, false)
        local pointed, screen, hit_pos
        repeat
            pointed = ray:next()
            if pointed and pointed.type == 'node' then
                local node = core.get_node(pointed.under)
                if node.name == 'sbz_luacontroller_devices:screen' then
                    screen = pointed.under
                    hit_pos = vector.subtract(pointed.intersection_point, screen)
                end
            end
        until screen or not pointed
        if not hit_pos then return end
        local fourdir = core.fourdir_to_dir(core.get_node(screen).param2)
        if fourdir.x > 0 then
            hit_pos.x = -1 * hit_pos.z
        elseif fourdir.x < 0 then
            hit_pos.x = hit_pos.z
        elseif fourdir.z < 0 then
            hit_pos.x = -1 * hit_pos.x
        end

        hit_pos.y = -1 * hit_pos.y

        local hitpixel = {}
        hitpixel.x = math.round((hit_pos.x + 0.5) * size) + 1
        hitpixel.y = math.round((hit_pos.y + 0.5) * size) + 1

        if hitpixel.x < 1 or hitpixel.x > size or hitpixel.y < 1 or hitpixel.y > size then return end
        local message = {
            x = hitpixel.x,
            y = hitpixel.y,
            player = player:get_player_name(),
        }

        sbz_luacs.send_luacomm_message(subscribed, message, screenpos)
    end,
    node_box = {
        type = 'fixed',
        fixed = { -0.5, -0.5, 0.4, 0.5, 0.5, 0.5 },
    },
    on_rotate = function(pos, ...)
        local ret = screwdriver.rotate_simple(pos, ...)
        core.after(0, update_display, pos)
        return ret
    end,
    groups = { matter = 3, ui_logic = 1 },
    sounds = sbz_api.sounds.machine(),
    _luacomm_receive = function(pos, msg, from_pos)
        local meta = core.get_meta(pos)
        if msg == 'subscribe' then
            meta:set_string('subscribed', vector.to_string(from_pos))
            return
        end

        if type(msg) ~= 'table' then return end
        local data = {}

        local size = #msg
        if size == 0 then return end

        local black = core.colorspec_to_bytes('black')

        for y = 1, size do
            data[y] = {}
            if type(msg[y]) ~= 'table' then msg[y] = {} end
            for x = 1, size do
                local v = msg[y][x]
                local bytes = core.colorspec_to_bytes(v) or black
                data[y][x] = bytes
            end
        end

        meta:set_string('data', core.serialize(data))
        update_display(pos)
    end,
})

core.register_lbm({
    name = 'sbz_luacontroller_devices:screen_respawn',
    label = 'Respawn screen entities',
    nodenames = { 'sbz_luacontroller_devices:screen' },
    run_at_every_load = true,
    action = update_display,
})

unified_inventory.register_craft {
    type = 'ele_fab',
    items = {
        'sbz_resources:lua_chip 2',
        'unifieddyes:colorium 32',
        'sbz_resources:emittrium_circuit 8',
        'sbz_resources:matter_plate 10',
    },
    output = 'sbz_luacontroller_devices:screen',
    width = 2,
    height = 2,
}
