local function on_rightclick(pos, _, _, itemstack)
	if not itemstack:is_empty() then
		-- not an empty hand
		return
	end

	local meta = minetest.get_meta(pos)
	local pos1 = minetest.string_to_pos(meta:get_string("pos1"))
	local pos2 = minetest.string_to_pos(meta:get_string("pos2"))
	local size = vector.add(vector.subtract(pos2, pos1), 1)


	local tool = ItemStack("pick_and_place:place 1")
	local tool_meta = tool:get_meta()
	tool_meta:set_string("size", minetest.pos_to_string(size))

	return tool
end


minetest.register_node("pick_and_place:handle", {
	description = "Pick and place handle",
	tiles = {"pick_and_place_plus.png"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
	on_rightclick = on_rightclick,
	groups = {
		oddly_breakable_by_hand = 3
	}
})
