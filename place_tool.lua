minetest.register_tool("pick_and_place:place", {
    description = "Placement tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#0000ff",
    stack_max = 1,
    range = 0,
    groups = {
        not_in_creative_inventory = 1
    },
    on_use = function(itemstack, player)
        local pointed_pos = pick_and_place.get_pointed_position(player)
        local meta = itemstack:get_meta()
        local schematic = meta:get_string("schematic")
        pick_and_place.deserialize(pointed_pos, schematic)
    end,
    on_step = function(itemstack, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)

        local meta = itemstack:get_meta()
        local size = minetest.string_to_pos(meta:get_string("size"))

        local pos2 = vector.add(pointed_pos, vector.subtract(size, 1))

        pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#0000ff", pointed_pos, pos2)
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})
