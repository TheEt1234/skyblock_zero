core.register_craftitem(':sbz_logic:data_disk', {
    description = 'Empty Data Disk',
    info_extra = 'Can hold 20 kilobytes.',
    data_disk_can_hold = 1024 * 20, -- 20 kilobytes
    inventory_image = 'data_disk.png',
    groups = { sbz_disk = 1, ui_logic = 1 },
})

unified_inventory.register_craft {
    type = 'ele_fab',
    width = 2,
    height = 1,
    output = 'sbz_logic:data_disk',
    items = {
        'sbz_resources:luanium 2',
        'sbz_resources:retaining_circuit 16',
    },
}
