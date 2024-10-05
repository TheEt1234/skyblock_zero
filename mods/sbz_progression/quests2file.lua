local text = {}
for k, v in ipairs(quests) do
    if v.type == "text" then
        text[#text + 1] = v.title
        text[#text + 1] = string.rep("-", #v.title)
        text[#text + 1] = v.text
        text[#text + 1] = string.rep("-", #v.title)
        text[#text + 1] = ""
    elseif v.type == "quest" or v.type == "secret" then
        text[#text + 1] = (v.type == "quest" and "Quest: " or "Secret: ") .. v.title
        text[#text + 1] = string.rep("-", #v.title)
        text[#text + 1] = v.text
        text[#text + 1] = string.rep("-", #v.title)

        if v.base then
            text[#text + 1] = "base"
        end
        if v.requires and #v.requires ~= 0 then
            text[#text + 1] = "depends: " .. table.concat(v.requires, ", ")
        end
        text[#text + 1] = string.rep("-", #v.title)
        text[#text + 1] = ""
    end
end

error("\n\n" .. table.concat(text, "\n") .. "\n\n")
