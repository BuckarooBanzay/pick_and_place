
minetest.register_tool("pick_and_place:placer", {
    description = "Placement tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#00ff00",
    stack_max = 1,
    range = 0,
    on_use = function(itemstack, player)
    end,
    on_focus = function(itemstack, player)
    end,
    on_step = function(itemstack, player)
    end,
    on_blur = function(player)
    end
})
