--[[
    quest_tree is a recursive datastructure, let me explain it

    tree = {
        quest = {},
        tree = {
            quest = {},
            tree = { and you get the idea }
        }
    }
]]

quest_tree = {}

-- quest_tree_name_index
local qtni = {}

local function filter(t, f)
    for k, v in ipairs(t) do
        if f(v) == false then
            t[v] = nil
        end
    end
end

-- this is O(n^2)
-- but optimizing this would most likely result in a gigantic waste of time

-- i will put this up just in case:
-- hours wasted: 0

local function sum(t)
    local sum = 0
    for k, v in pairs(t) do
        sum = sum + v
    end
    return sum
end

local function calc_width(tree)
    local function internal(t, w, og)
        if #t.tree ~= 1 and not og then
            w[#w + 1] = #t.tree
        end
        for k, v in ipairs(t.tree) do
            internal(v, w)
        end
    end

    local function internal_2(t)
        local widths = {}
        internal(t, widths, false)
        t.cached_width = math.max(#t.tree, sum(widths))
        for k, v in ipairs(t.tree) do
            internal_2(v)
        end
    end
    internal_2(tree)
end

local function gen_tree(t)
    t = table.copy(t) -- important
    filter(t, function(v)
        if v.type == "questline" then return false end
        if v.type == "secret" then return false end
    end)

    for k, quest in ipairs(t) do -- needs to be in order
        if quest.base then
            quest_tree.quest = quest
            quest_tree.tree = {}
            qtni[quest.title] = quest_tree -- root
        elseif quest.parent and qtni[quest.parent] then
            local parent = qtni[quest.parent]
            local idx = #parent.tree + 1
            parent.tree[idx] = {
                quest = quest,
                tree = {}
            }
            qtni[quest.title] = parent.tree[idx]
        end
    end
    calc_width(quest_tree)
end



gen_tree(quests)


-- License for the function make_scrollbaroptions_for_scroll_container:
--[[
License of minetest: https://github.com/minetest/minetest/blob/master/LICENSE.txt

Minetest
Copyright (C) 2022 rubenwardy

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

Only applies to the function below, everything else is licensed normally as in LICENSE.txt
]]
--- Creates a scrollbaroptions for a scroll_container
--
-- @param visible_l the length of the scroll_container and scrollbar
-- @param total_l length of the scrollable area
-- @param scroll_factor as passed to scroll_container
local function make_scrollbaroptions_for_scroll_container(visible_l, total_l, scroll_factor)
    --    assert(total_l >= visible_l)
    local max = total_l - visible_l
    local thumb_size = (visible_l / total_l) * max
    return ("scrollbaroptions[min=0;max=%f;thumbsize=%f]"):format(max / scroll_factor, thumb_size / scroll_factor)
end


function sbz_api.draw_questbook_formspec()
    local HORIZ_SPACING = 0.5 -- multiplier
    local scroll_vert_max = 50
    local scroll_horiz_max = 3 * (quest_tree.cached_width * HORIZ_SPACING)
    local fs = ([[
formspec_version[7]
size[20,20]
container[0.2,0.2]


    scroll_container[0,0;19.1,19.6;scrollbar_horiz;horizontal;0.1]
        scroll_container[0,0;190.1,190.6;scrollbar_vert;vertical;0.1]
            %s
        scroll_container_end[]
    scroll_container_end[]

    %s scrollbar[0,19.1;19.1,0.5;horizontal;scrollbar_horiz;0]
    %s scrollbar[19.1,0;0.5,19.1;vertical;scrollbar_vert;0]
container_end[]

    ]])

    local boxes = {}
    local quest_buttons = {}
    local VERT_SPACING = 1
    local SIZE = 0.5
    local BOX_WIDTH = 0.2
    local BOX_COLOR = "#ffffff"

    local function draw(node, x1, y1, x2, y2)
        local half_width = BOX_WIDTH / 2
        local dx, dy = x1 - x2, y1 - y2

        local add_half_width = true
        if x1 ~= x2 then
            local x = x2
            local had_to_abs = false
            if dx < 0 then
                x = x + dx
                dx = math.abs(dx)
                had_to_abs = true
            end
            table.insert(boxes, ("box[%s,%s;%s,%s;%s]"):format(x, y2 + half_width, dx, BOX_WIDTH, BOX_COLOR))
            x2 = x1

            add_half_width = false
            y2 = y2 + (had_to_abs and half_width + BOX_WIDTH or half_width)
        end
        if y1 ~= y2 then
            table.insert(boxes,
                ("box[%s,%s;%s,%s;%s]"):format(x2 + (add_half_width and half_width or 0), y2, BOX_WIDTH, dy,
                    BOX_COLOR))
        end
        table.insert(quest_buttons, ("button[%s,%s;%s,%s;%s;X]"):format(x1, y1, SIZE, SIZE, node.quest.title))
        table.insert(quest_buttons, ("tooltip[%s;%s]"):format(node.quest.title, node.quest.title))
    end

    local function lerp(a, b, x)
        return a + ((b - a) * x)
    end
    local function norm(x, min, max)
        return (x - min) / (max - min)
    end

    local function traverse(node, x, y, bx, by) -- bx,by = before x, before y
        draw(node, x, y, bx, by)                -- draw self
        if #node.tree == 1 then                 -- draw node above
            y = y + VERT_SPACING
            draw(node.tree[1], x, y, x, y - VERT_SPACING)
        elseif #node.tree > 1 then
            local width = node.cached_width * HORIZ_SPACING
            local h = width / 2 -- half
            bx, by = x, y       -- update bx,by

            y = y + VERT_SPACING

            local max = -math.huge
            local min = math.huge
            for k, v in pairs(node.tree) do
                if v.cached_width > max then max = v.cached_width end
                if v.cached_width < min then min = v.cached_width end
            end

            local occupied = 0
            for k, v in pairs(node.tree) do
                occupied = occupied + norm(v.cached_width, min, max)
                local tx = lerp(x - h, x + h, occupied)
                traverse(v, tx, y, bx, by)
            end
        end
    end

    local h = (quest_tree.cached_width) * HORIZ_SPACING
    traverse(quest_tree, h, 1, h, 1)
    fs = fs:format(table.concat({ table.concat(boxes, ""), table.concat(quest_buttons, "") }, ""),
        make_scrollbaroptions_for_scroll_container(20, scroll_horiz_max, 0.1),
        make_scrollbaroptions_for_scroll_container(20, scroll_vert_max, 0.1))
    return fs
end
