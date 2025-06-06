local FORMSPEC_NAME = "pick_and_place:configure_tool"

-- playername -> pos (if pos1 selected)
local pos1 = {}

-- playername -> pos (if pos2 selected)
local pos2 = {}

-- previously used name and category for each player
local player_last_names = {}
local player_last_categories = {}

-- sets the last used name and category to be used in new configure-handles
function pick_and_place.set_configure_handle_preset(playername, name, category)
    player_last_names[playername] = name
    player_last_categories[playername] = category
end

minetest.register_tool("pick_and_place:configure", {
    description = "Placement configuration tool",
    inventory_image = "pick_and_place.png^[colorize:#ffffff",
    stack_max = 1,
    range = 0,
    on_use = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)

        if pos1[playername] then
            -- second position selected
            pos2[playername] = pointed_pos

            -- show name input
            minetest.show_formspec(playername, FORMSPEC_NAME, [[
                size[10,4]
                real_coordinates[true]

                field[0.1,0.5;9.8,0.8;name;Name;]] .. (player_last_names[playername] or "") .. [[]
                field[0.1,1.7;9.8,0.8;category;Category;]] .. (player_last_categories[playername] or "") .. [[]

                button_exit[0.1,2.8;9.8,0.8;save;Save]
            ]])
        else
            -- first position selected
            pos1[playername] = pointed_pos
        end
    end,
    on_secondary_use = function(_, player)
        local playername = player:get_player_name()
        pos1[playername] = nil
    end,
    on_step = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)
        local pointed_pos2 = pos1[playername]
        local text = pick_and_place.get_formatted_size(pointed_pos, pointed_pos2)

        -- update preview
        pick_and_place.show_preview(playername, "pick_and_place.png", "#ffffff", pointed_pos, pointed_pos2, text)
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    if not fields.save and not fields.key_enter_field then
        return true
    end

    local playername = player:get_player_name()
    if not pos1[playername] or not pos2[playername] then
        return true
    end

    -- configure and unmark
    pick_and_place.configure(pos1[playername], pos2[playername], fields.name, fields.category)
    pos1[playername] = nil
    pos2[playername] = nil

    -- store for next time
    player_last_names[playername] = fields.name
    player_last_categories[playername] = fields.category

    return true
end)