function pick_and_place.create_tool(pos1, pos2, name, player)
    local size = vector.add(vector.subtract(pos2, pos1), 1)

    local tool = ItemStack("pick_and_place:place 1")
    local tool_meta = tool:get_meta()
    tool_meta:set_string("size", minetest.pos_to_string(size))

    -- player rotation on pickup
    tool_meta:set_int("rotation", pick_and_place.get_player_rotation(player))

    -- serialize schematic
    local schematic = pick_and_place.serialize(pos1, pos2)
    tool_meta:set_string("schematic", schematic)

    local desc = string.format(
        "Placement tool '%s' (%d bytes, size: %s)",
        name or "", #schematic, minetest.pos_to_string(size)
    )
    tool_meta:set_string("description", desc)

    return tool
end