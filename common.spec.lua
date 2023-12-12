
mtt.register("sort_pos", function(callback)
    local pos1 = { x = 10, y = 20, z = 30 }
    local pos2 = { x = 10, y = 10, z = 10 }

    pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)

    assert(pos1.x == 10)
    assert(pos1.y == 10)
    assert(pos1.z == 10)
    assert(pos2.x == 10)
    assert(pos2.y == 20)
    assert(pos2.z == 30)

    callback()
end)