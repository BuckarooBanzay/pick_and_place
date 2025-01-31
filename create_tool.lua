function pick_and_place.create_tool_from_schematic(schematic, name, id)
    local tool = ItemStack("pick_and_place:place 1")
    local tool_meta = tool:get_meta()
    tool_meta:set_string("size", minetest.pos_to_string(schematic.size))

    local encoded_schematic = pick_and_place.encode_schematic(schematic)
    tool_meta:set_string("schematic", encoded_schematic)

    -- set name and id
    tool_meta:set_string("name", name)
    tool_meta:set_string("id", id)

    -- add rotation info (with respect to original in-world build)
    tool_meta:set_int("rotation", 0)

    -- update description
    pick_and_place.update_placement_tool_description(tool_meta)

    return tool
end

function pick_and_place.create_tool(pos1, pos2, name, id)
    return pick_and_place.create_tool_from_schematic(pick_and_place.serialize(pos1, pos2), name, id)
end

function pick_and_place.update_placement_tool_description(tool_meta)
    local name = tool_meta:get_string("name")
    local id = tool_meta:get_string("id")
    local size_str = tool_meta:get_string("size")
    local schematic = tool_meta:get_string("schematic")
    local rotation = tool_meta:get_int("rotation")

    local desc = string.format(
        "Placement tool '%s' / '%s' (%d bytes, rotation: %d°, size: %s)",
        name or "", id or "", #schematic, rotation, size_str
    )
    tool_meta:set_string("description", desc)
end