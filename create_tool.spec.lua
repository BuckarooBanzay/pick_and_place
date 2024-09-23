
local pos1 = {x=0, y=0, z=0}
local pos2 = {x=10, y=10, z=20}

mtt.emerge_area(pos1, pos2)

mtt.register("create_tool and rotate", function(callback)
    minetest.set_node(pos1, { name = "default:mese" })

    local tool = pick_and_place.create_tool(pos1, pos2, "my build", "1234")
    assert(tool)
    local meta = tool:get_meta()
    assert(meta:get_string("description"))
    assert(meta:get_int("rotation") == 0)

    local success, err = pick_and_place.rotate_tool(tool, 90)
    assert(success)
    assert(not err)
    assert(meta:get_string("description"))
    assert(meta:get_int("rotation") == 90)

    success, err = pick_and_place.rotate_tool(tool, 270)
    assert(success)
    assert(not err)
    assert(meta:get_string("description"))
    assert(meta:get_int("rotation") == 0)

    callback()
end)