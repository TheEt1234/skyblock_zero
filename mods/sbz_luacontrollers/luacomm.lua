-- "luacomm" is the name of this protocol
-- Order of arguments: pos, message:any (except cdata/functions/userdata/threads), from_pos
--
-- To be able to receive messages from this protocol, you MUST be a node and have _luacomm_receive = function(from_pos, pos, message) [...] end in your node definition
--
-- interpret the name as "*luac*ontroller *comm*unication"
--
-- Also, **the messages sent through this protocol should be limited in size (as determined by sbz_luacs.object_size) by sbz_luacs.max_luacomm_message_length**

function sbz_luacs.send_luacomm_message(pos, msg, from_pos)
    local msg = sbz_luacs.object_size(msg, sbz_luacs.max_luacomm_message_length, true)
    if not msg then return false end
    sbz_luacs.delay(0, sbz_luacs.delayable_functions.luacomm, pos, msg, from_pos)
    return true
end

---@class core.NodeDef
---@field _luacomm_receive? fun(pos, msg, from_pos)

-- Internal
function sbz_luacs.delayable_functions.luacomm(pos, msg, from_pos)
    local node_at_pos = sbz_api.get_or_load_node(pos).name
    local ndef = core.registered_nodes[node_at_pos]
    if ndef and ndef._luacomm_receive then ndef._luacomm_receive(pos, msg, from_pos) end
end
