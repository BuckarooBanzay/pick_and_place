
-- playername => key
local active_preview = {}

function pick_and_place.show_preview(playername, texture, color, pos1, pos2, text)
	pos2 = pos2 or pos1
	texture = texture .. "^[colorize:" .. color

	pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)

	local key =
		minetest.pos_to_string(pos1) .. "/" ..
		minetest.pos_to_string(pos2) .. "/" ..
		texture .. "/" ..
		(text or "")

	if active_preview[playername] == key then
		-- already active on the same region
		return
	end
	-- clear previous entities
	pick_and_place.clear_preview(playername)
	active_preview[playername] = key

	local visual_size = vector.add(vector.subtract(pos2, pos1), 1)
	local offset = vector.divide(vector.subtract(pos2, pos1), 2)
	local origin = vector.subtract(pos2, offset)

	local ent = pick_and_place.add_entity(origin, key)
	ent:set_properties({
		visual_size = visual_size,
		nametag = text,
		textures = {
			texture,
			texture,
			texture,
			texture,
			texture,
			texture
		}
	})
end

function pick_and_place.clear_preview(playername)
	if active_preview[playername] then
		pick_and_place.remove_entities(active_preview[playername])
		active_preview[playername] = nil
	end
end

minetest.register_on_leaveplayer(function(player)
	pick_and_place.clear_preview(player:get_player_name())
end)