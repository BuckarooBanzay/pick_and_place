local FORMSPEC_NAME = "pick_and_place:composition"

local function get_formspec(_, pos, meta)
    local name = minetest.formspec_escape(meta:get_string("name"))
    local id = meta:get_string("id")

    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    local active_pos = pick_and_place.get_active_composition_pos()
    local active = active_pos and vector.equals(active_pos, pos)
    local status = "Not active"
    if active then
        status = minetest.colorize("#00FF00", "Active")
    end

    return [[
        size[10,5]
        real_coordinates[true]

        label[0.1,0.5;Name]
        field[2,0;6,1;name;;]] .. name .. [[]
        button_exit[8,0;2,1;save;Save]

        label[0.1,2.5;Stats]
        label[2,2.5;]] .. "ID: " .. id .. " Entries: " .. entries .. " / " .. bytes .. " bytes" .. [[]

        label[0.1,3.5;Status]
        label[2,3.5;]] .. status .. [[]

        label[0.1,4.5;Actions]
        button_exit[2,4;2,1;]] .. (active and "pause;Pause" or "record;Record") .. [[]
        button_exit[4,4;2,1;playback;Playback]
        button_exit[6,4;2,1;mark_area;Mark Area]
        button_exit[8,4;2,1;duplicate;Duplicate]
    ]]
end

-- playername -> node position for formspec
local fs_pos = {}

local function copy_metadata(oldmeta, newmeta)
    for _, key in ipairs({"id", "name", "data", "entries", "description"}) do
        newmeta:set_string(key, oldmeta:get_string(key))
    end
end

minetest.register_node("pick_and_place:composition", {
    description = "Composition",
    tiles = {"pick_and_place_composition.png^[colorize:#0000ff"},
    stack_max = 1,
	drawtype = "allfaces",
	use_texture_alpha = "blend",
	paramtype = "light",
	sunlight_propagates = true,
	groups = {
		oddly_breakable_by_hand = 3
	},
	on_rightclick = function(pos, _, player)
        local meta = minetest.get_meta(pos)
        pick_and_place.update_composition_node(meta)
        local playername = player:get_player_name()
		fs_pos[playername] = pos
        minetest.show_formspec(playername, FORMSPEC_NAME, get_formspec(player, pos, meta))
    end,
    on_place = function(itemstack, placer, pointed_thing)
        local _, pos = minetest.item_place(itemstack, placer, pointed_thing)
        if pos then
            local meta = minetest.get_meta(pos)
            copy_metadata(itemstack:get_meta(), meta)
            pick_and_place.update_composition_node(meta)
            return pos, ItemStack()
        else
            return
        end
    end,
    on_dig = function(pos, _, player)
        -- pause composition if active
        local active_pos = pick_and_place.get_active_composition_pos()
        if active_pos and vector.equals(active_pos, pos) then
            pick_and_place.set_active_composition_pos(nil)
        end

        -- create itemstack
        local oldmeta = minetest.get_meta(pos)
        local itemstack = ItemStack("pick_and_place:composition")
        local meta = itemstack:get_meta()
        copy_metadata(oldmeta, meta)

        local remove_node = false

        -- add to player inv
        if player:get_wielded_item():is_empty() then
            -- empty slot/hand
		    player:set_wielded_item(itemstack)
            remove_node = true
        else
            -- anywhere in the inventory
            local inv = player:get_inventory()
            if inv:add_item("main", itemstack):is_empty() then
                remove_node = true
            end
        end

        -- remove node
        if remove_node then
            minetest.set_node(pos, { name = "air" })
        end

        return true
    end
})

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

    if fields.save then
        pick_and_place.update_composition_fields(meta, fields)
    elseif fields.record then
        pick_and_place.set_active_composition_pos(pos)
    elseif fields.pause then
        pick_and_place.set_active_composition_pos(nil)
    elseif fields.playback then
        pick_and_place.play_composition(pos, meta, playername)
    elseif fields.mark_area then
        pick_and_place.mark_composition_area(pos, meta, playername)
    elseif fields.duplicate then
        pick_and_place.duplicate_composition_node(meta, playername)
    end

    return true
end)