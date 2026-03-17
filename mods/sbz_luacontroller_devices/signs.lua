core.register_on_mods_loaded(function()
    for name, _ in pairs(core.registered_nodes) do
        if core.get_item_group(name, 'sign_luac_compatible') == 1 then
            core.override_item(name, {
                _luacomm_receive = function(pos, msg, _)
                    if type(msg) ~= 'string' then return end
                    signs_lib.update_sign(pos, {
                        text = msg,
                    })
                end,
            })
        end
    end
end)
