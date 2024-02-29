mtt.register("rotate", function(callback)

    local schematic = {
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
    }

    pick_and_place.schematic_rotate(schematic, 90)

    assert(schematic.node_id_data[1] == 0)
    assert(schematic.node_id_data[2] == 2)
    assert(schematic.metadata["(0,0,1)"])

    callback()
end)