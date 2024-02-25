
local function get_outer_corners(pos1, pos2)
    pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)
    pos1 = vector.subtract(pos1, 1)
    pos2 = vector.add(pos2, 1)

    return {
        { x=pos1.x, y=pos1.y, z=pos1.z },
        { x=pos1.x, y=pos1.y, z=pos2.z },
        { x=pos1.x, y=pos2.y, z=pos1.z },
        { x=pos1.x, y=pos2.y, z=pos2.z },
        { x=pos2.x, y=pos1.y, z=pos1.z },
        { x=pos2.x, y=pos1.y, z=pos2.z },
        { x=pos2.x, y=pos2.y, z=pos1.z },
        { x=pos2.x, y=pos2.y, z=pos2.z }
    }
end

function pick_and_place.configure(pos1, pos2, name)
    pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)

    for _, cpos in ipairs(get_outer_corners(pos1, pos2)) do
        local node = minetest.get_node(cpos)
        if node.name == "air" then
            minetest.set_node(cpos, { name = "pick_and_place:handle" })
            local meta = minetest.get_meta(cpos)

            -- relative positions
            local rel_pos1 = vector.subtract(pos1, cpos)
            local rel_pos2 = vector.subtract(pos2, cpos)

            meta:set_string("pos1", minetest.pos_to_string(rel_pos1))
            meta:set_string("pos2", minetest.pos_to_string(rel_pos2))
            meta:set_string("name", name)
            meta:set_string("infotext", name)
        end
    end
end