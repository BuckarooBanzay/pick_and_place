
local function update_formspec(meta)
    local group = meta:get_string("group")

    meta:set_string("formspec", [[
        size[10,8.3]
        real_coordinates[true]
        field[0.1,0.4;8.8,0.8;group;Group;]] .. group .. [[]
        button_exit[9,0.4;0.9,0.8;set;Set]
        list[context;main;0.1,1.4;8,1;]
        list[current_player;main;0.1,3;8,4;]
        listring[]
    ]])

    local txt = "Replacement node wallmounted"
    if group and group ~= "" then
        txt = txt .. " (group: '" .. group .. "')"
    end
    meta:set_string("infotext", txt)
end

minetest.register_node("pick_and_place:replacement_wallmounted", {
	description = "Replacement node wallmounted",
	tiles = {"pick_and_place.png^[colorize:#ff0000"},
    drawtype = "signlike",
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "wallmounted",
    walkable = false,
	climbable = true,
    sunlight_propagates = true,
    selection_box = {
		type = "wallmounted"
    },
	groups = {
		oddly_breakable_by_hand = 3
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 8)

        update_formspec(meta)
	end,

    on_receive_fields = function(pos, _, fields)
        if fields.set then
            local meta = minetest.get_meta(pos)
            meta:set_string("group", fields.group)
            update_formspec(meta)
        end
    end
})
