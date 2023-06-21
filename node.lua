
minetest.register_node("pick_and_place:handle", {
	description = "Pick and place handle",
	tiles = {"pick_and_place_plus.png"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
	groups = {
		oddly_breakable_by_hand = 3
	}
})

minetest.register_node("pick_and_place:handle_configured", {
	description = "Pick and place handle (configured)",
	tiles = {"pick_and_place_plus.png^[colorize:#00ff00"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
	groups = {
		oddly_breakable_by_hand = 3,
        not_in_creative_inventory = 1
	}
})