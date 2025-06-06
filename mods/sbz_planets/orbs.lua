--[[
    Orb maker: needs all orbs to be crafted, makes orbs

    Dwarf orb: used to make the planet finder
]]



core.register_craftitem("sbz_planets:dwarf_orb", {
    description = "Dwarf Orb",
    inventory_image = "dwarf_orb.png",
    info_extra = "Used as a crafing replacement for matter annihilators, found naturally in dwarf planets",
})
core.register_craft {
    type = "shapeless",
    output = "sbz_planets:dwarf_orb 16",
    recipe = {
        "sbz_meteorites:neutronium", "sbz_resources:pebble", "sbz_planets:dwarf_orb",
    }
}

core.register_node("sbz_planets:dwarf_orb_ore", {
    description = "Dwarf Orb Ore",
    groups = {
        matter = 1, antimatter = 1, ore = 1, level = 2,
    },
    drop = "sbz_planets:dwarf_orb",
    tiles = { "stone.png^dwarf_orb.png" }
})

core.register_node("sbz_planets:dwarf_stone", {
    description = "Stone",
    tiles = { "stone.png" },
    groups = { matter = 1, charged = 1, moss_growable = 1, not_in_creative_inventory = 1, explody = 10 },
    sounds = sbz_api.sounds.matter(),
    drop = "sbz_resources:stone"
})

core.register_ore {
    ore_type = "scatter",
    ore = "sbz_planets:dwarf_orb_ore",
    wherein = "sbz_planets:dwarf_stone",
    y_min = 2000,
    clust_scarcity = 16 ^ 3,
    clust_num_ores = 8,
    clust_size = 1,
}
