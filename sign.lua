
local function update_formspec(meta)

    meta:set_string("formspec", [[
        size[10,8.3]
        real_coordinates[true]
        dropdown[0.1,0.1;9.8;type;Streetname,Floor;1]
        button_exit[9,1.4;0.9,0.8;set;Set]
    ]])

    local txt = "Replacement node for signs"
    meta:set_string("infotext", txt)
end

local node_box = {
    type="fixed",
    fixed = {
        -0.5, -0.5, 0.3, 0.5, 0.5, 0.5
    }
}

minetest.register_node("pick_and_place:replacement_sign", {
	description = "Replacement node for signs",
	tiles = {
        "pick_and_place_txt.png^[colorize:#ff0000"
    },
    drawtype = "nodebox",
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
	selection_box = node_box,
    collision_box = node_box,
    node_box = node_box,
    groups = {
		oddly_breakable_by_hand = 3
	},
    on_construct = function(pos)
		local meta = minetest.get_meta(pos)
        update_formspec(meta)
	end,
    on_receive_fields = function(pos, _, fields)
        print(dump(fields))
        if fields.set then
            local meta = minetest.get_meta(pos)
            meta:set_string("group", fields.group)
            update_formspec(meta)
        end
    end
})
