local function on_rightclick(pos, _, player, itemstack)
	if not itemstack:is_empty() then
		-- not an empty hand
		return
	end

	local meta = minetest.get_meta(pos)

	-- relative positions
	local rel_pos1 = minetest.string_to_pos(meta:get_string("pos1"))
	local rel_pos2 = minetest.string_to_pos(meta:get_string("pos2"))
	local name = meta:get_string("name")

	if not rel_pos1 or not rel_pos2 then
		-- not configured
		return
	end

	-- absolute positions
	local pos1 = vector.add(pos, rel_pos1)
	local pos2 = vector.add(pos, rel_pos2)

	return pick_and_place.create_tool(pos1, pos2, name, player)
end


minetest.register_node("pick_and_place:handle", {
	description = "Pick and place handle",
	tiles = {"pick_and_place.png"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
	on_rightclick = on_rightclick,
	drop = "",
	groups = {
		oddly_breakable_by_hand = 3
	}
})
