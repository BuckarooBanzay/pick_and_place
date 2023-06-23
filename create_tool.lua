function pick_and_place.create_tool(pos1, pos2)
    local size = vector.add(vector.subtract(pos2, pos1), 1)

    local tool = ItemStack("pick_and_place:place 1")
    local tool_meta = tool:get_meta()
    tool_meta:set_string("size", minetest.pos_to_string(size))

    -- serialize schematic
    local schematic = pick_and_place.serialize(pos1, pos2)
    tool_meta:set_string("schematic", schematic)

    local desc = string.format("Placement tool (%d bytes, size: %s)", #schematic, minetest.pos_to_string(size))
    tool_meta:set_string("description", desc)

    return tool
end