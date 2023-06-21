
minetest.register_tool("pick_and_place:placer", {
    description = "Placement tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#00ff00",
    stack_max = 1,
    range = 0,
    on_use = function(itemstack, player)
        print("on_use: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end,
    on_focus = function(itemstack, player)
        print("on_focus: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end,
    on_step = function(itemstack, player)
        print("on_step: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end,
    on_blur = function(itemstack, player)
        print("on_blur: " .. itemstack:get_name() .. ", " .. player:get_player_name())
    end
})
