
minetest.register_tool("pick_and_place:placer", {
    description = "Placement tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#00ff00",
    stack_max = 1,
    range = 0,
    on_use = function(itemstack, player)
        print("on_use: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end,
    on_secondary_use = function(itemstack, player)
        print("on_secondary_use: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end,
    on_step = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)
        pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#00ff00", pointed_pos, vector.add(pointed_pos, {x=1, y=2, z=3}))
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})
