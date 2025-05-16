local FORMSPEC_NAME = "pick_and_place:composition"

local function get_formspec(_, pos, meta)
    local name = minetest.formspec_escape(meta:get_string("name"))

    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    local active_pos = pick_and_place.get_active_composition_pos()
    local active = active_pos and vector.equals(active_pos, pos)
    local status = "Not active"
    if active then
        status = minetest.colorize("#00FF00", "Active")
    end

    local inv_location = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z

    return [[
        size[12,14]
        real_coordinates[true]

        label[0.1,0.25;Name]
        field[2,0;8,0.5;name;;]] .. name .. [[]
        button_exit[10,0;2,0.5;save;Save]

        label[0.1,0.75;Status]
        label[2,0.75;]] ..
            " Entries: " ..
            entries .. " / " ..
            bytes .. " bytes, " ..
            status ..
        [[]

        label[0.1,1.25;Replacements (from -> to)]
        list[]] .. inv_location .. [[;replacements;0.3,1.5;2,5;0]
        list[]] .. inv_location .. [[;replacements;3.3,1.5;2,5;10]
        list[]] .. inv_location .. [[;replacements;6.3,1.5;2,5;20]
        list[]] .. inv_location .. [[;replacements;9.3,1.5;2,5;30]
        list[current_player;main;1,8;8,4;]
        listring[]

        button_exit[0,13;3,1;]] .. (active and "pause;Pause" or "record;Record") .. [[]
        button_exit[3,13;3,1;playback;Playback]
        button_exit[6,13;3,1;mark_area;Mark Area]
        button_exit[9,13;3,1;duplicate;Duplicate]
    ]]
end

-- playername -> node position for formspec
local fs_pos = {}

local function copy_metadata(oldmeta, newmeta)
    for _, key in ipairs({"name", "data", "entries", "description"}) do
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
            local item_meta = itemstack:get_meta()
            copy_metadata(item_meta, meta)
            pick_and_place.update_composition_node(meta)

            -- deserialize inventory
            local replacements_inv = meta:get_inventory()
            local replacements = item_meta:get_string("replacements")
            for i, r in ipairs(minetest.deserialize(replacements)) do
                replacements_inv:set_stack("replacements", i, ItemStack(r))
            end

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

        -- serialize replacements
        local oldinv = oldmeta:get_inventory()
        local replacements = {}
        for _, r in ipairs(oldinv:get_list("replacements")) do
            table.insert(replacements, r:to_string())
        end
        meta:set_string("replacements", minetest.serialize(replacements))

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
    end,
    on_metadata_inventory_move = function(pos)
        pick_and_place.notify_change(pos, pos)
    end,
    on_metadata_inventory_put = function(pos)
        pick_and_place.notify_change(pos, pos)
    end,
    on_metadata_inventory_take = function(pos)
        pick_and_place.notify_change(pos, pos)
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

    pick_and_place.notify_change(pos, pos)
    return true
end)