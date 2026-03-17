local base_formspec = [[
formspec_version[10]
size[20,14.2]
tabheader[0,0;tab;Code,Terminal,Documentation;%s;false;true]
style_type[*;font=mono]
style[start;bgcolor=#00ff00]
style[stop;bgcolor=#ff0000]
style_type[textarea;textcolor=]
]]

-- TODO: There may be cases where the user wants the term tab and the code tab at once

local base_code_tab = [[
container[.4,.4]
style_type[textarea;border=false,textcolor=white]
%s
textarea[0,0;19.2,12.6;code;;%s]
button[0,12.6;2,.8;save;Save]
button[2,12.6;2,.8;%s;%s]
container_end[]
]]

local base_term_tab = [[
container[.4,.4]

style_type[*;noclip=true]
box[0,0;19.2,12.4;#111111FF]
textarea[0,0;19.2,12.4;;;%s]

set_focus[term_input;true]
field_enter_after_edit[term_input;true]
field_close_on_enter[term_input;false]
field[0,12.4;15.2,1;term_input;_;]

button[15.2,12.4;2,1;send;Send]
button[17.2,12.4;2,1;clear;Clear]

container_end[]
]]

local tabs = {
    code = '1',
    terminal = '2',
    docs = '3',
}

function sbz_luacs.ui(pos, meta, fields, sender)
    if sender then sbz_api.ui.set_player(sender) end
    fields = fields or { tab = meta:get_string('current_tab') }

    if fields.tab == '0' or not fields.tab then fields.tab = meta:get_string('current_tab') end
    meta:set_string('current_tab', fields.tab)

    if not fields.code then fields.code = meta:get_string('code') end
    meta:set_string('code', fields.code) -- save code

    local fs = { base_formspec:format(fields.tab) }

    if fields.clear then meta:set_string('terminal', '') end

    if fields.start and not sbz_luacs.is_on(meta) then sbz_luacs.set_state(pos, meta, true) end
    if fields.stop and sbz_luacs.is_on(meta) then sbz_luacs.set_state(pos, meta, false) end

    if fields.term_input and fields.term_input ~= '' then
        sbz_luacs.send_event_to_sandbox(pos, { type = 'terminal', msg = fields.term_input })
    end

    if fields.tab == tabs.code then
        local code_box

        local padding = 0.1
        if sender then
            code_box = sbz_api.ui.box(0 - padding, 0 - padding, 19.2 + padding, 12.6 + padding)
        else
            code_box = 'box[0,0;19.2,12.6;#000000ff]'
        end
        fs[#fs + 1] = base_code_tab:format(
            code_box,
            core.formspec_escape(fields.code),
            sbz_luacs.is_on(meta) and 'stop' or 'start',
            sbz_luacs.is_on(meta) and 'Stop' or 'Start'
        )
    elseif fields.tab == tabs.terminal then
        fs[#fs + 1] = base_term_tab:format(core.formspec_escape(meta:get_string('terminal')))
    end

    meta:set_string('formspec', table.concat(fs))
    sbz_api.ui.del_player()
end

function sbz_luacs.on_receive_fields(pos, _, fields, sender)
    local sender_name = sender:get_player_name()
    if core.is_protected(pos, sender_name) then
        core.record_protection_violation(pos, sender_name)
        return
    end

    local meta = core.get_meta(pos)
    sbz_luacs.ui(pos, meta, fields, sender)
end

sbz_luacs.loglevels = {
    verbose = 1,
    info = 2,
    default = 3,
    warning = 4, -- "You did something wrong but i am not going to error" - use rarely, prefer error-ing when you can
    error = 5,
}

sbz_luacs.loglevel_prefixes = {
    [sbz_luacs.loglevels.verbose] = '[verbose] ',
    [sbz_luacs.loglevels.info] = '[info] ',
    [sbz_luacs.loglevels.default] = '',
    [sbz_luacs.loglevels.error] = '[error] ',
    [sbz_luacs.loglevels.warning] = '[warning] ',
}

function sbz_luacs.luac_print(pos, loglevel, msg)
    local meta = core.get_meta(pos)
    local term = meta:get_string('terminal')
    assert(sbz_luacs.loglevel_prefixes[loglevel], 'Invalid loglevel, Report this as a bug')
    msg = sbz_luacs.loglevel_prefixes[loglevel] .. msg .. '\n'
    term = term .. msg
    term = string.sub(term, math.max(0, #term - sbz_luacs.term_max_char_limit), #term)
    meta:set_string('terminal', term)

    -- NOTE: is that annoying
    local active_tab = meta:get_string('current_tab')
    if active_tab == tabs.terminal then sbz_luacs.ui(pos, meta) end
end

function sbz_luacs.luac_error(pos, err)
    err = tostring(err)
    local lines = string.split(err, '\n')
    for _, line in ipairs(lines) do
        sbz_luacs.luac_print(pos, sbz_luacs.loglevels.error, line)
    end
end
