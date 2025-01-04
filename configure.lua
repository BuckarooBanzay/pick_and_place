
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
    for _, hpos in ipairs(pick_and_place.get_outer_corners(pos1, pos2)) do
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
function pick_and_place.configure(pos1, pos2, name, id)
    pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)
    id = id or pick_and_place.create_id()
    pick_and_place.register_template(pos1, pos2, name, id)

    for _, cpos in ipairs(pick_and_place.get_outer_corners(pos1, pos2)) do
        local node = minetest.get_node(cpos)
        if node.name == "air" or node.name == "pick_and_place:handle" then
            minetest.swap_node(cpos, { name = "pick_and_place:handle" })
            local meta = minetest.get_meta(cpos)

            -- relative positions
            local rel_pos1 = vector.subtract(pos1, cpos)
            local rel_pos2 = vector.subtract(pos2, cpos)

            meta:set_string("pos1", minetest.pos_to_string(rel_pos1))
            meta:set_string("pos2", minetest.pos_to_string(rel_pos2))
            meta:set_string("name", name)
            meta:set_string("id", id)
            meta:set_string("infotext", pick_and_place.get_handle_infotext(meta))
        end
    end
end