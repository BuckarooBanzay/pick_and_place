
-- make sure we don't have any other nodes around
local pos1 = {x=20, y=20, z=20}
local pos2 = {x=25, y=25, z=25}

mtt.emerge_area(pos1, pos2)

mtt.register("configure handles and remove", function(callback)
    minetest.set_node(pos1, { name = "default:mese" })

    pick_and_place.configure(pos1, pos2, "my build")
    assert(minetest.get_node(vector.subtract(pos1, 1)).name == "pick_and_place:handle")
    assert(minetest.get_node(vector.add(pos2, 1)).name == "pick_and_place:handle")

    local success, err = pick_and_place.remove_handles(vector.add(pos2, 1))
    assert(success)
    assert(not err)

    assert(minetest.get_node(vector.subtract(pos1, 1)).name == "air")
    assert(minetest.get_node(vector.add(pos2, 1)).name == "air")

    callback()
end)