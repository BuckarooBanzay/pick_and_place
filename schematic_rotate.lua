
function pick_and_place.schematic_rotate(node_ids, param2_data, metadata, max, rotation)
    if rotation <= 0 or rotation > 270 then
        -- invalid or no rotation
        return
    end

    local other1, other2 = "x", "z"

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
end

