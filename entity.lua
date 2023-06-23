
-- id -> true
local active_entities = {}

minetest.register_entity("pick_and_place:display", {
	initial_properties = {
		physical = false,
        static_save = false,
		collisionbox = {0, 0, 0, 0, 0, 0},
		visual = "cube",
		visual_size = {x=1, y=1, z=1},
		glow = 10
	},
	on_step = function(self)
		if not active_entities[self.id] then
			-- not valid anymore
			self.object:remove()
		end
	end
})

function pick_and_place.add_entity(pos, id)
	active_entities[id] = true
	local ent = minetest.add_entity(pos, "pick_and_place:display")
	local luaent = ent:get_luaentity()
	luaent.id = id
	return ent
end

function pick_and_place.remove_entities(id)
	active_entities[id] = nil
end
