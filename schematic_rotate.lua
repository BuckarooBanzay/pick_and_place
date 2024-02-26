
function pick_and_place.schematic_rotate(schematic, rotation)
    print(dump({
        fn = "before",
        schematic = schematic,
        rotation = rotation
    }))

    if rotation <= 0 or rotation > 270 then
        -- invalid or no rotation
        return
    end

    local other1, other2 = "x", "z"

    local node_ids = schematic.node_id_data
    local param2_data = schematic.param2_data
    local metadata = schematic.metadata
    local max = vector.subtract(schematic.size, 1)

    if rotation == 90 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_transpose(node_ids, param2_data, metadata, max, other1, other2)
    elseif rotation == 180 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other2)
    elseif rotation == 270 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_transpose(node_ids, param2_data, metadata, max, other1, other2)
    end

    pick_and_place.schematic_orient(node_ids, param2_data, max, rotation)

    -- rotate size
    schematic.size = pick_and_place.rotate_size(schematic.size, rotation)

    print(dump({
        fn = "after",
        schematic = schematic,
        max = max
    }))
end

