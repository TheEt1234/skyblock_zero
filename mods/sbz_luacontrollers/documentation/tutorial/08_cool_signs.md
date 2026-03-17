# Cool signs

This is the beginning of the fun part.

The matter/antimatter signs can communicate using luacomm. They accept a string (the text to be displayed).

```lua
luacomm_send(links.sign, "Meow")
```

But we can do more fun things, like animating them

Let's animate the colors

```lua
local text = "Meow Meow Meow Meow Meow Meow"

local colors = { [0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"}
local shift_by = 0
while true do
    shift_by = shift_by + 1
    local new_text = {}
    for i = 1, #text do
        local char = text:sub(i, i)
        table.insert(new_text, "#")
        table.insert(new_text, colors[(i + shift_by) % #colors])
        table.insert(new_text, char)
    end

    luacomm_send(links.sign, table.concat(new_text))
    wait(0.2)
end
```
