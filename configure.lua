
-- returns the outer corners for the handle nodes
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

-- true if already in removal function (disables recursion through on_destruct)
local in_removal = false

-- removes all other handle nodes
function pick_and_place.remove_handles(handle_pos)
    if in_removal then
        return
    end

    local node = minetest.get_node(handle_pos)
    if node.name ~= "pick_and_place:handle" then
        return false, "not a valid handle node @ " .. minetest.pos_to_string(handle_pos)
    end

    local meta = minetest.get_meta(handle_pos)
    local pos1 = minetest.string_to_pos(meta:get_string("pos1"))
    local pos2 = minetest.string_to_pos(meta:get_string("pos2"))

    local name = meta:get_string("name")
    if not name or not pos1 or not pos2 then
        return false, "unexpected metadata"
    end

    -- resolve to absolute coords
    pos1 = vector.add(pos1, handle_pos)
    pos2 = vector.add(pos2, handle_pos)

    in_removal = true

    pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)
    for _, hpos in ipairs(get_outer_corners(pos1, pos2)) do
        local hnode = minetest.get_node(hpos)
        if hnode.name == "pick_and_place:handle" then
            local hmeta = minetest.get_meta(hpos)
            if hmeta:get_string("name") == name then
                -- name and node matches, remove
                minetest.set_node(hpos, { name = "air" })
            end
        end
    end

    in_removal = false

    return true
end

-- sets handle nodes where possible
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