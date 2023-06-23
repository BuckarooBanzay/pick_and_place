
-- playername -> pos (if pos1 selected)
local pos1 = {}

minetest.register_tool("pick_and_place:pick", {
    description = "Pick tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#00ff00",
    stack_max = 1,
    range = 0,
    on_use = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)

        if pos1[playername] then
            -- second position selected

            -- configure and create tool
            local p1, p2 = pick_and_place.sort_pos(pos1[playername], pointed_pos)

            local tool = pick_and_place.create_tool(p1, p2)
            pos1[playername] = nil
            return tool
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

        if pos1[playername] then
            -- first position already selected
            pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#00ff00", pointed_pos, pos1[playername])
        else
            -- nothing selected yet
            pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#00ff00", pointed_pos)
        end
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})