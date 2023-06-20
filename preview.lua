
-- playername => key
local active_preview = {}

local function add_preview_entity(texture, key, visual_size, pos, rotation)
	local ent = pick_and_place.add_entity(pos, key)
	ent:set_properties({
		visual_size = visual_size,
		textures = {texture}
	})
	ent:set_rotation(rotation)
end

function pick_and_place.show_preview(playername, texture, color, pos1, pos2)
	texture = texture .. "^[colorize:" .. color

	local key =
		minetest.pos_to_string(pos1) .. "/" ..
		minetest.pos_to_string(pos2) .. "/" ..
		texture

	if active_preview[playername] == key then
		-- already active on the same region
		return
	end
	-- clear previous entities
	pick_and_place.clear_preview(playername)
	active_preview[playername] = key

	local size = vector.subtract(pos2, pos1)
	local half_size = vector.divide(size, 2) -- 8 .. n

	-- z-
	add_preview_entity(texture, key,
		{x=size.x, y=size.y},
		vector.add(pos1, {x=half_size.x-0.5, y=half_size.y-0.5, z=-0.5}),
		{x=0, y=0, z=0}
	)

	-- z+
	add_preview_entity(texture, key,
		{x=size.x, y=size.y},
		vector.add(pos1, {x=half_size.x-0.5, y=half_size.y-0.5, z=size.z-0.5}),
		{x=0, y=0, z=0}
	)

	-- x-
	add_preview_entity(texture, key,
		{x=size.z, y=size.y},
		vector.add(pos1, {x=-0.5, y=half_size.y-0.5, z=half_size.z-0.5}),
		{x=0, y=math.pi/2, z=0}
	)

	-- x+
	add_preview_entity(texture, key,
		{x=size.z, y=size.y},
		vector.add(pos1, {x=size.x-0.5, y=half_size.y-0.5, z=half_size.z-0.5}),
		{x=0, y=math.pi/2, z=0}
	)

	-- y-
	add_preview_entity(texture, key,
		{x=size.x, y=size.z},
		vector.add(pos1, {x=half_size.x-0.5, y=-0.5, z=half_size.z-0.5}),
		{x=math.pi/2, y=0, z=0}
	)

	-- y+
	add_preview_entity(texture, key,
		{x=size.x, y=size.z},
		vector.add(pos1, {x=half_size.x-0.5, y=size.y-0.5, z=half_size.z-0.5}),
		{x=math.pi/2, y=0, z=0}
	)

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