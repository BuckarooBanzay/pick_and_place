-- returns the absolute positions and name for the handle
-- TODO: a better name perhaps?
function pick_and_place.get_template_data_from_handle(pos)
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

	return pos1, pos2, name
end

local function on_rightclick(pos, _, _, itemstack)
	if not itemstack:is_empty() then
		-- not an empty hand
		return
	end

	local pos1, pos2, name = pick_and_place.get_template_data_from_handle(pos)
	if not pos1 or not pos2 then
		return
	end

	return pick_and_place.create_tool(pos1, pos2, name)
end


minetest.register_node("pick_and_place:handle", {
	description = "Pick and place handle",
	tiles = {"pick_and_place.png"},
    drawtype = "allfaces",
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
	on_rightclick = on_rightclick,
	on_destruct = pick_and_place.remove_handles,
	drop = "",
	groups = {
		oddly_breakable_by_hand = 3,
		not_in_creative_inventory = 1
	}
})

minetest.register_lbm({
	label = "register pick-and-place handles",
	name = "pick_and_place:handle_register",
	nodenames = {"pick_and_place:handle"},
	run_at_every_load = true,
	action = function(pos)
		local pos1, pos2, name = pick_and_place.get_template_data_from_handle(pos)
		pick_and_place.register_template(name, pos1, pos2)
	end
})