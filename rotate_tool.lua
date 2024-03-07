
function pick_and_place.rotate_tool(itemstack, rotation)
    if itemstack:get_name() ~= "pick_and_place:place" then
        return false, "unexpected item"
    end

    local meta = itemstack:get_meta()
    local schematic_data = meta:get_string("schematic")
    local schematic, err = pick_and_place.decode_schematic(schematic_data)
    if err then
        return false, "Schematic decode error: " .. err
    end

    -- rotate schematic
    pick_and_place.schematic_rotate(schematic, rotation)
    meta:set_string("schematic", pick_and_place.encode_schematic(schematic))

    -- set new rotation info
    local old_rotation = meta:get_int("rotation")
    local new_rotation = old_rotation + rotation
    if new_rotation >= 360 then
        new_rotation = new_rotation - 360
    end
    meta:set_int("rotation", new_rotation)

    -- rotate size
    local size = minetest.string_to_pos(meta:get_string("size"))
    size = pick_and_place.rotate_size(size, rotation)
    meta:set_string("size", minetest.pos_to_string(size))

    -- update description
    pick_and_place.update_placement_tool_description(meta)

    return true
end