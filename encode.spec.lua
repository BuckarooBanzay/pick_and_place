
mtt.register("encode", function(callback)
    local data = pick_and_place.encode_schematic({
        node_id_data = {0, 0, 0, 0, 1, 2, 3, 4},
        param2_data = {0, 0, 0, 0, 4, 3, 2, 1},
        metadata = {
            ["(0,0,0)"] = {
                meta = {
                    x = 1
                },
                inventory = {
                    main = {"default:stick 1"}
                }
            }
        },
        size = {
            x = 2,
            y = 2,
            z = 2
        }
    })

    assert(data)

    local schematic, err = pick_and_place.decode_schematic(data)
    assert(not err)
    assert(schematic)

    assert(#schematic.node_id_data, 8)
    assert(#schematic.param2_data, 8)
    assert(schematic.metadata["(0,0,0)"])
    assert(schematic.size.x == 2)
    assert(schematic.size.y == 2)
    assert(schematic.size.z == 2)

    callback()
end)