local FORMSPEC_NAME = "pick_and_place:handle_node"

-- returns the absolute positions and name for the handle
-- TODO: a better name perhaps?
function pick_and_place.get_template_data_from_handle(pos, meta)
	-- relative positions
	local rel_pos1 = minetest.string_to_pos(meta:get_string("pos1"))
	local rel_pos2 = minetest.string_to_pos(meta:get_string("pos2"))
	local name = meta:get_string("name")
	local category = meta:get_string("category") or ""
	local id = meta:get_string("id")
	if id == "" then
		id = pick_and_place.create_id()
	end

	if not rel_pos1 or not rel_pos2 then
		-- not configured
		return
	end

	-- absolute positions
	local pos1 = vector.add(pos, rel_pos1)
	local pos2 = vector.add(pos, rel_pos2)

	return pos1, pos2, name, category, id
end

function pick_and_place.get_handle_infotext(meta)
	return "Handle, " ..
		"Name: '" .. meta:get_string("name") ..
		"' Category: '" .. meta:get_string("category") ..
		"' Id: '" .. meta:get_string("id") .. "'"
end

-- migrate
local function migrate_handle(pos, meta)
	if meta:get_string("id") == "" then
		-- legacy node without id, reconfigure
		local pos1, pos2, name, _, id = pick_and_place.get_template_data_from_handle(pos, meta)
		pick_and_place.configure(pos1, pos2, name, id)
		meta:set_string("infotext", pick_and_place.get_handle_infotext(meta))
	end
end

local function get_formspec(meta)
	return [[
		size[10,4]
		real_coordinates[true]

		field[0.1,0.5;9.8,0.8;name;Name;]] .. meta:get_string("name") .. [[]

		field[0.1,1.7;9.8,0.8;category;Category;]] .. meta:get_string("category") .. [[]

		button_exit[0.1,2.8;3.2,0.8;mark;Mark with WE]
		button_exit[3.4,2.8;3.2,0.8;pick;Pick]
		button_exit[6.7,2.8;3.2,0.8;save;Save]
	]]
end

-- playername -> node position for formspec
local fs_pos = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= FORMSPEC_NAME then
		return false
	end

	local playername = player:get_player_name()
	local pos = fs_pos[playername]
	if not pos then
		return true
	end

	local meta = minetest.get_meta(pos)
	local pos1, pos2, name, _, id = pick_and_place.get_template_data_from_handle(pos, meta)

	if fields.save then
		-- reconfigure handles
		pick_and_place.configure(pos1, pos2, fields.name, fields.category, id)
		pick_and_place.set_configure_handle_preset(playername, fields.name, fields.category)
	elseif fields.mark and minetest.get_modpath("worldedit") then
		worldedit.pos1[playername] = pos1
		worldedit.pos2[playername] = pos2
		worldedit.mark_pos1(playername);
		worldedit.mark_pos2(playername);
	elseif fields.pick then
		local itemstack = player:get_wielded_item()
		if not itemstack:is_empty() then
			-- not an empty hand
			return
		end
		itemstack = pick_and_place.create_tool(pos1, pos2, name, id)
		player:set_wielded_item(itemstack)
	end

    return true
end)

minetest.register_node("pick_and_place:handle", {
	description = "Pick and place handle",
	tiles = {"pick_and_place.png"},
	drawtype = "allfaces",
	use_texture_alpha = "blend",
	paramtype = "light",
	sunlight_propagates = true,
	on_rightclick = function(pos, _, clicker)
		local meta = minetest.get_meta(pos)
		local playername = clicker:get_player_name()
		fs_pos[playername] = pos
		minetest.show_formspec(playername, FORMSPEC_NAME, get_formspec(meta))
	end,
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
		local meta = minetest.get_meta(pos)
		migrate_handle(pos, meta)
		local pos1, pos2, name, category, id = pick_and_place.get_template_data_from_handle(pos, meta)
		pick_and_place.register_template(pos1, pos2, name, category, id)
	end
})