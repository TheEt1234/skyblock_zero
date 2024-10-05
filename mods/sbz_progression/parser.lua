local SEP = "--"
quests = {}

local function starts(x, y)
    return string.sub(x, 1, #y) == y
end

local function transform(t, f)
    for k, v in pairs(t) do
        t[v] = f(v)
    end
end

local function obtain_section(text, ptr)
    local section = ""
    while true do
        local line = text[ptr]

        assert(line,
            "An error while parsing quests occured: <missing the entire context, sorry> - Didn't close with dashes")

        if starts(line, SEP) then
            ptr = ptr + 1
            break
        end
        section = section .. line .. "\n"
        ptr = ptr + 1
    end
    return section, ptr
end

function sbz_api.load_quests(text, err_context)
    -- ok great, i've made some really really basic parsers before (like for ANSI, that project was fucking hell and i wish i could go all about it in this comment), shouldnt be too hard
    text = string.split(text, "\n", true)
    local ptr = 1


    local apply = {}

    local function format_error(line, msg)
        error(string.format("An error while parsing quests occured: %s:%s - %s", err_context or "<unknown>", line, msg))
    end

    repeat -- repeat until... i am evil
        local line = text[ptr]

        if starts(line, "Questline: ") then
            local questline_title = string.trim(line)
            ptr = ptr + 1
            line = text[ptr]
            if not starts(line, SEP) then
                format_error(ptr, "This line should be filled with at least 2 dashes.")
            end
            ptr = ptr + 1

            local questline_text
            questline_text, ptr = obtain_section(text, ptr)
            apply[#apply + 1] = {
                type = "text",
                title = questline_title,
                text = questline_text
            }
        end

        if starts(line, "Quest:") or starts(line, "Secret:") then
            local quest = {
                type = "quest"
            }
            local is_secret = starts(line, "Secret: ")
            local title = string.trim(line)
            if is_secret then
                title = string.sub(title, #"Secret: " + 1)
                quest.type = "secret"
            else
                title = string.sub(title, #"Quest: " + 1)
            end
            quest.title = title
            -- now the quest text...
            ptr = ptr + 1
            line = text[ptr]
            if not starts(line, SEP) then
                format_error(ptr, "This line should be filled with at least 2 dashes.")
            end
            ptr = ptr + 1
            local quest_text
            quest_text, ptr = obtain_section(text, ptr)
            quest.text = quest_text

            local prop_text

            prop_text, ptr = obtain_section(text, ptr)
            prop_text = string.split(prop_text, "\n")

            for _, line in pairs(prop_text) do -- no need for ptr2 yet :D
                assert(not starts(line, "Depends:"), "Nitpick: it's \"depends:\" and !!NOT!! \"Depends:\"!!")
                if starts(line, "depends: ") then
                    local depends = string.split(string.sub(line, #"depends: " + 1), ",")
                    transform(depends, string.trim)
                    quest.requires = depends
                end
                if starts(line, "base") then
                    quest.base = true
                elseif starts(line, "parent: ") then
                    local parent = string.trim(string.sub(line, #"parent: " + 1))
                    quest.parent = parent
                end
            end

            quest.requires = quest.requires or {}

            if not quest.parent then
                quest.parent = quest.requires[1]
            end

            apply[#apply + 1] = quest
        end

        -- this is now pointless whitespace
        ptr = ptr + 1
    until ptr > #text

    for k, v in ipairs(apply) do
        quests[#quests + 1] = v
    end
end

function sbz_api.load_quests_file(path)
    local file = assert(io.open(path), "File not found")
    sbz_api.load_quests(file:read("*a"), path)
    file:close()
end

local files_to_load = {
    [1] = "Introduction"
}

local path_starter = minetest.get_modpath("sbz_progression") .. "/quests/"
for k, v in ipairs(files_to_load) do
    sbz_api.load_quests_file(path_starter .. v .. ".txt")
end
